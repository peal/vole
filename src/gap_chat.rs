use std::{
    fs::File,
    io::prelude::*,
    io::{BufReader, BufWriter},
    path::PathBuf,
    sync::Mutex,
};

use std::io::Write;

use structopt::StructOpt;

#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    #[structopt(parse(from_os_str))]
    pub input: Option<PathBuf>,

    #[structopt(parse(from_os_str))]
    pub output: Option<PathBuf>,

    #[structopt(short, long)]
    pub inpipe: Option<i32>,
    #[structopt(short, long)]
    pub outpipe: Option<i32>,

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

pub struct GapChatType {
    pub in_file: Box<dyn BufRead + Send>,
    pub out_file: Box<dyn Write + Send>,
}

lazy_static! {
    pub static ref OPTIONS: Opt = Opt::from_args();
    pub static ref GAP_CHAT: Mutex<GapChatType> = {
        let opt = &OPTIONS;
        Mutex::new(GapChatType {
            in_file: Box::new(opt.input()),
            out_file: Box::new(opt.output()),
        })
    };
}

impl GapChatType {
    pub fn send_request<T, U>(request: &T) -> U
    where
        T: serde::Serialize,
        U: serde::de::DeserializeOwned,
    {
        let gap_channel = &mut GAP_CHAT.lock().unwrap();
        serde_json::to_writer(&mut gap_channel.out_file, request).unwrap();

        let mut line = String::new();
        let _ = gap_channel.in_file.read_line(&mut line).unwrap();

        let out: U = serde_json::from_str(&line).unwrap();
        out
    }
}
