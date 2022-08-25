//! Communicate with GAP, both to recieve original problem and ask
//! mathematical questions during search

use std::{
    fmt,
    io::prelude::*,
    io::{BufReader, BufWriter},
    path::PathBuf,
    sync::{Mutex, MutexGuard},
};

use anyhow::anyhow;
use anyhow::{Context, Error, Result};
use serde::{Deserialize, Serialize};
use tracing::{debug, trace};

use std::io::Write;

use structopt::StructOpt;

use crate::vole::{solutions::Solutions, stats::Stats};

/// Store command line arguments
#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    /// Input file
    #[structopt(parse(from_os_str))]
    input: Option<PathBuf>,

    /// Output file
    #[structopt(parse(from_os_str))]
    output: Option<PathBuf>,

    /// Input pipe (as a POSIX file id)
    #[structopt(short, long)]
    inpipe: Option<i32>,

    /// Output pipe (as a POSIX file id)
    #[structopt(short, long)]
    outpipe: Option<i32>,

    /// TCP port
    #[structopt(short, long)]
    port: Option<i32>,

    /// Enable tracing
    #[structopt(short, long)]
    pub trace: bool,

    /// Be quiet (hide rust backtraces on crash)
    #[structopt(short, long)]
    pub quiet: bool,
}

/// Store communication channels with GAP
pub struct GapChatType {
    /// Communication channel to GAP
    pub in_file: Option<Box<dyn BufRead + Send>>,
    /// Communication channel from GAP
    out_file: Option<Box<dyn Write + Send>>,
}

impl Opt {
    #[cfg(target_family = "unix")]
    fn in_out_unix(&self) -> GapChatType {
        use std::os::unix::io::FromRawFd;
        trace!("Linking to GAP");
        let in_file = Box::new(BufReader::new(unsafe {
            std::fs::File::from_raw_fd(self.inpipe.unwrap())
        }));
        let out_file = Box::new(BufWriter::new(unsafe {
            std::fs::File::from_raw_fd(self.outpipe.unwrap())
        }));
        GapChatType {
            in_file: Some(in_file),
            out_file: Some(out_file),
        }
    }

    #[cfg(not(target_family = "unix"))]
    fn in_out_unix(&self) -> GapChatType {
        panic!("Unix sockets are not supported on this platform");
    }

    fn in_out_net(&self) -> GapChatType {
        trace!("Making socket");
        let socket = std::net::SocketAddr::new(
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(127, 0, 0, 1)),
            self.port.unwrap() as u16,
        );
        trace!("Connecting to GAP");
        let t = std::net::TcpStream::connect(socket).expect("Unable to make connection from ferret to GAP");
        trace!("Cloning socket");
        let t2 = t.try_clone().unwrap();
        trace!("Connecting finished");
        GapChatType {
            in_file: Some(Box::new(BufReader::new(t))),
            out_file: Some(Box::new(BufWriter::new(t2))),
        }
    }

    fn in_out(&self) -> GapChatType {
        assert!(
            self.inpipe.is_some() == self.outpipe.is_some(),
            "must declare both --inpipe and --outpipe, or neither"
        );
        assert!(
            self.inpipe.is_some() != self.port.is_some(),
            "must declare either --inpipe or --port, but not both"
        );
        if self.inpipe.is_some() && self.outpipe.is_some() {
            self.in_out_unix()
        } else {
            self.in_out_net()
        }
    }
}

lazy_static! {
    /// Global command line arguments
    pub static ref OPTIONS: Opt = Opt::from_args();
    /// Global communication channel with GAP
    pub static ref GAP_CHAT: Mutex<GapChatType> = {
        let opt = &OPTIONS;
        Mutex::new(opt.in_out())
    };
}

#[derive(Debug, Deserialize, Serialize)]
struct GapError {
    error: String,
}

impl GapChatType {
    /// Send an object to GAP, and receive a reply. `T` is serialized
    /// to JSON, and the reply is deserialized into type `U`.
    pub fn send_request<T, U>(request: &T) -> Result<U, Error>
    where
        T: serde::Serialize + std::fmt::Debug,
        U: serde::de::DeserializeOwned + std::fmt::Debug,
    {
        let gap_channel = GAP_CHAT.lock().unwrap();
        Self::send_request_internal(request, gap_channel)
    }

    /// Send an error -- we assume this is the last thing we will send to GAP
    pub fn send_error(error: String) {
        let _: Result<String, Error> = Self::send_request(&("error", error));
    }

    /// A variant of send_request where, if communication is already in progress
    /// will return fail instead.
    fn try_send_request<T, U>(request: &T) -> Result<U, Error>
    where
        T: serde::Serialize + std::fmt::Debug,
        U: serde::de::DeserializeOwned + std::fmt::Debug,
    {
        let gap_channel = GAP_CHAT.try_lock();
        match gap_channel {
            Ok(guard) => Self::send_request_internal(request, guard),
            Err(_) => Err(anyhow!("<GAP busy>")),
        }
    }

    fn send_request_internal<T, U>(request: &T, mut gap_channel: MutexGuard<Self>) -> Result<U, Error>
    where
        T: serde::Serialize + std::fmt::Debug,
        U: serde::de::DeserializeOwned + std::fmt::Debug,
    {
        let gap_channel = &mut *gap_channel;
        let i_file = &mut gap_channel.in_file;
        let o_file = &mut gap_channel.out_file;
        let mut out_file = o_file.as_mut().ok_or_else(|| anyhow!("no network"))?;
        let in_file = i_file.as_mut().ok_or_else(|| anyhow!("no network"))?;
        debug!("Sending to GAP: {:?}", serde_json::to_string(request));
        serde_json::to_writer(&mut out_file, request)?;
        writeln!(&mut out_file)?;
        out_file.flush()?;
        debug!("Sent to GAP, now reading");
        let mut line = String::new();
        let _ = in_file
            .read_line(&mut line)
            .map_err(anyhow::Error::msg)
            .context("Internal error in communication between vole and GAP")?;

        let out: U = serde_json::from_str(&line)?;
        debug!("Recieving from GAP: {:?}", out);
        Ok(out)
    }
}
#[derive(Debug, Deserialize, Serialize)]
struct Results {
    sols: Vec<Vec<usize>>,
    canonical: Option<Vec<usize>>,
    search_fix_order: Vec<usize>,
    stats: Stats,
    rbase_branches: Vec<usize>,
}

impl GapChatType {
    /// Send results (list of permutations) and rbase (which can be used as a redundant base)
    /// to GAP
    pub fn send_results(
        &mut self,
        solutions: &Solutions,
        fixed: &[usize],
        rbase_base: &[usize],
        stats: Stats,
    ) -> anyhow::Result<()> {
        let sols: Vec<Vec<usize>> = solutions
            .get()
            .iter()
            .map(|s| s.as_vec().iter().map(|x| x + 1).collect())
            .collect();
        let search_fix_order = fixed.iter().map(|&x| x + 1).collect();

        let rbase_branches = rbase_base.iter().map(|&x| x + 1).collect();
        let canonical = solutions
            .get_canonical()
            .as_ref()
            .map(|c| c.perm.as_vec().iter().map(|&x| x + 1).collect());

        serde_json::to_writer(
            &mut (self.out_file.as_mut().unwrap()),
            &(
                "end",
                Results {
                    sols,
                    canonical,
                    search_fix_order,
                    stats,
                    rbase_branches,
                },
            ),
        )?;
        writeln!(&mut self.out_file.as_mut().unwrap())?;
        self.out_file.as_mut().unwrap().flush()?;

        debug!("Sent results to GAP, now reading");
        let mut closing_message = String::new();
        let _ = self.in_file.as_mut().unwrap().read_line(&mut closing_message)?;
        assert_eq!(closing_message.trim(), "goodbye");
        Ok(())
    }

    pub fn close(&mut self) {
        self.in_file = None;
        self.out_file = None;
    }
}

/// A reference to a GAP variable
#[derive(Deserialize, Serialize, Hash)]
pub struct GapRef {
    id: isize,
}

impl Drop for GapRef {
    fn drop(&mut self) {
        // We do not expect a return from this
        // We purposefully ignore any errors from this, as they can occur while
        // the program is closing
        let v: Result<Vec<usize>, Error> = GapChatType::send_request(&("dropGapRef", self));
        assert!(v.is_err() || v.unwrap().is_empty());
    }
}

impl fmt::Debug for GapRef {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s: Result<String, Error> = GapChatType::try_send_request(&("stringGapRef", self));
        let str = match s {
            Ok(s) => s,
            Err(e) => e.to_string(),
        };

        f.debug_struct("GapRef")
            .field("id", &self.id)
            .field("value", &str)
            .finish()
    }
}
