use rust_peal::trace;
use rust_peal::vole::parseinput;
use rust_peal::vole::search::simple_search;
use rust_peal::vole::solutions::Solutions;
use rust_peal::vole::state::PartitionState;

use simplelog::*;

use std::path::PathBuf;
use structopt::StructOpt;

use std::{
    fs::File,
    io::prelude::*,
    io::{BufReader, BufWriter},
};

#[cfg(target_os = "linux")]
use os::unix::io::FromRawFd;

#[cfg(target_os = "linux")]
#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    #[structopt(short, long)]
    pub inpipe: Option<i32>,
    #[structopt(short, long)]
    pub outpipe: Option<i32>,

    #[structopt(short, long)]
    pub trace: bool,
}

#[cfg(not(target_os = "linux"))]
#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    #[structopt(parse(from_os_str))]
    pub input: PathBuf,

    #[structopt(parse(from_os_str))]
    pub output: PathBuf,

    #[structopt(short, long)]
    pub trace: bool,
}

impl Opt {
    #[cfg(target_os = "linux")]
    fn input(&self) -> impl BufRead {
        BufReader::new(unsafe { File::from_raw_fd(self.inpipe.unwrap()) })
    }

    #[cfg(not(target_os = "linux"))]
    fn input(&self) -> impl BufRead {
        // TODO Error handle
        BufReader::new(File::open(&self.input).unwrap())
    }

    #[cfg(target_os = "linux")]
    fn output(&self) -> impl Write {
        BufReader::new(unsafe { File::from_raw_fd(self.outpipe.unwrap()) })
    }

    #[cfg(not(target_os = "linux"))]
    fn output(&self) -> impl Write {
        BufWriter::new(File::open(&self.output).unwrap())
    }
}

fn main() -> anyhow::Result<()> {
    let opt = Opt::from_args();

    CombinedLogger::init(vec![
        TermLogger::new(LevelFilter::Info, Config::default(), TerminalMode::Mixed).unwrap(),
        WriteLogger::new(
            LevelFilter::Info,
            Config::default(),
            File::create("vole-trace.log").unwrap(),
        ),
    ])
    .unwrap();

    let mut infile = opt.input();
    let mut outfile = opt.output();

    let problem = parseinput::read_problem(&mut infile)?;

    let mut constraints = parseinput::build_constraints(&problem.constraints);
    let tracer = trace::Tracer::new();

    let mut state = PartitionState::new(problem.config.points, tracer);
    let mut solutions = Solutions::default();
    simple_search(&mut state, &mut solutions, &mut constraints);

    solutions.write_one_indexed(&mut outfile)?;
    Ok(())
}
