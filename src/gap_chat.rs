    use std::{fs::File, io::prelude::*, io::{BufReader, BufWriter}, path::PathBuf, sync::Mutex};
    
    use std::io::Write;
    
    #[cfg(target_os = "linux")]
    use std::os::unix::io::FromRawFd;
    
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
        #[cfg(target_os = "linux")]
        fn input(&self) -> impl BufRead + Send{
            BufReader::new(unsafe { File::from_raw_fd(self.inpipe.unwrap()) })
        }
    
        #[cfg(not(target_os = "linux"))]
        fn input(&self) -> impl BufRead + Send{
            // TODO Error handle
            BufReader::new(File::open(&self.input).unwrap())
        }
    
        #[cfg(target_os = "linux")]
        fn output(&self) -> impl Write + Send {
            BufWriter::new(unsafe { File::from_raw_fd(self.outpipe.unwrap()) })
        }
    
        #[cfg(not(target_os = "linux"))]
        fn output(&self) -> impl Write + Send {
            BufWriter::new(File::open(&self.output).unwrap())
        }
    }


pub struct GapChatType {
  pub in_file : Box<dyn BufRead + Send>,
  pub out_file : Box<dyn Write + Send>
}

lazy_static! {
    pub static ref OPTIONS : Opt =  Opt::from_args() ;
    pub static ref GAP_CHAT : Mutex<GapChatType> = {
    let opt = &OPTIONS;
    Mutex::new(GapChatType{in_file: Box::new(opt.input()), out_file: Box::new(opt.output())})
    };
}