//! Communicate with GAP, both to recieve original problem and ask
//! mathematical questions during search

use std::{
    fmt,
    fs::File,
    io::prelude::*,
    io::{BufReader, BufWriter},
    path::PathBuf,
    sync::Mutex,
};

use serde::{Deserialize, Serialize};
use tracing::debug;

use std::io::Write;

use structopt::StructOpt;

use crate::vole::{solutions::Solutions, stats::Stats};

/// Store command line arguments
#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    /// Input file
    #[structopt(parse(from_os_str))]
    pub input: Option<PathBuf>,

    /// Output file
    #[structopt(parse(from_os_str))]
    pub output: Option<PathBuf>,

    /// Input pipe (as a POSIX file id)
    #[structopt(short, long)]
    pub inpipe: Option<i32>,

    /// Output pipe (as a POSIX file id)
    #[structopt(short, long)]
    pub outpipe: Option<i32>,

    /// Enable tracing
    #[structopt(short, long)]
    pub trace: bool,
}

impl Opt {
    #[cfg(target_family = "unix")]
    fn input(&self) -> impl BufRead + Send {
        use std::os::unix::io::FromRawFd;
        BufReader::new(unsafe { File::from_raw_fd(self.inpipe.unwrap()) })
    }

    #[cfg(not(target_family = "unix"))]
    fn input(&self) -> impl BufRead + Send {
        // TODO Error handle
        BufReader::new(File::open(&self.input).unwrap())
    }

    #[cfg(target_family = "unix")]
    fn output(&self) -> impl Write + Send {
        use std::os::unix::io::FromRawFd;
        BufWriter::new(unsafe { File::from_raw_fd(self.outpipe.unwrap()) })
    }

    #[cfg(not(target_family = "unix"))]
    fn output(&self) -> impl Write + Send {
        BufWriter::new(File::open(&self.output).unwrap())
    }
}

/// Store communication channels with GAP
pub struct GapChatType {
    /// Communication channel to GAP
    pub in_file: Box<dyn BufRead + Send>,
    /// Communication channel from GAP
    pub out_file: Box<dyn Write + Send>,
}

lazy_static! {
    /// Global command line arguments
    pub static ref OPTIONS: Opt = Opt::from_args();
    /// Global communication channel with GAP
    pub static ref GAP_CHAT: Mutex<GapChatType> = {
        let opt = &OPTIONS;
        Mutex::new(GapChatType {
            in_file: Box::new(opt.input()),
            out_file: Box::new(opt.output()),
        })
    };
}

impl GapChatType {
    /// Send an object to GAP, and receieve a reply. `T` is serialised
    /// to JSON, and the reply is deserialised into type `U`.
    pub fn send_request<T, U>(request: &T) -> U
    where
        T: serde::Serialize + std::fmt::Debug,
        U: serde::de::DeserializeOwned + std::fmt::Debug,
    {
        let gap_channel = &mut GAP_CHAT.lock().unwrap();
        debug!("Sending to GAP: {:?}", request);
        serde_json::to_writer(&mut gap_channel.out_file, request).unwrap();
        writeln!(gap_channel.out_file).unwrap();
        gap_channel.out_file.flush().unwrap();

        let mut line = String::new();
        let _ = gap_channel.in_file.read_line(&mut line).unwrap();

        let out: U = serde_json::from_str(&line).unwrap();
        debug!("Recieving from GAP: {:?}", out);
        out
    }
}
#[derive(Debug, Deserialize, Serialize)]
struct Results {
    sols: Vec<Vec<usize>>,
    base: Vec<usize>,
    stats: Stats,
}

impl GapChatType {
    /// Send results (list of permutations) and rbase (which can be used as a redundant base)
    /// to GAP
    pub fn send_results(
        &mut self,
        solutions: &Solutions,
        rbase: &[usize],
        stats: Stats,
    ) -> anyhow::Result<()> {
        let sols: Vec<Vec<usize>> = solutions
            .get()
            .iter()
            .map(|s| s.as_vec().iter().map(|x| x + 1).collect())
            .collect();

        let base = rbase.iter().map(|&x| x + 1).collect();

        serde_json::to_writer(&mut self.out_file, &("end", Results { sols, base, stats }))?;
        self.out_file.flush()?;
        Ok(())
    }
}

/// Represent a variable stored in GAP
#[derive(Deserialize, Serialize, Hash)]
pub struct GapRef {
    id: isize,
}

impl Drop for GapRef {
    fn drop(&mut self) {
        // We do not expect a return from this
        let v: Vec<usize> = GapChatType::send_request(&("dropGapRef", self));
        assert!(v.is_empty());
    }
}

impl fmt::Debug for GapRef {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s: String = GapChatType::send_request(&("stringGapRef", self));
        f.debug_struct("GapRef")
            .field("id", &self.id)
            .field("value", &s)
            .finish()
    }
}
