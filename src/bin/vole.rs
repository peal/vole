use rust_peal::vole::search::simple_search;
use rust_peal::vole::solutions::Solutions;
use rust_peal::vole::state::PartitionState;
use rust_peal::vole::trace;
use rust_peal::vole::{parse_input, search::RefinerStore};

use tracing::Level;
use tracing_subscriber::{self, fmt::format::FmtSpan};

use structopt::StructOpt;

use std::{
    fs::File,
    io::prelude::*,
    io::{BufReader, BufWriter},
};

use std::io::Write;

#[cfg(target_os = "linux")]
use std::os::unix::io::FromRawFd;

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
        BufWriter::new(unsafe { File::from_raw_fd(self.outpipe.unwrap()) })
    }

    #[cfg(not(target_os = "linux"))]
    fn output(&self) -> impl Write {
        BufWriter::new(File::open(&self.output).unwrap())
    }
}

fn main() -> anyhow::Result<()> {
    let opt = Opt::from_args();

    let (non_block, _guard) = tracing_appender::non_blocking(File::create("vole.trace")?);

    tracing_subscriber::fmt()
        .with_span_events(FmtSpan::ACTIVE)
        .with_max_level(Level::TRACE)
        //.pretty()
        .with_writer(non_block)
        .init();

    let mut in_file = opt.input();
    let mut out_file = opt.output();

    let problem = parse_input::read_problem(&mut in_file)?;

    let mut constraints =
        RefinerStore::new_from_refiners(parse_input::build_constraints(&problem.constraints));
    let tracer = trace::Tracer::new();

    let mut state = PartitionState::new(problem.config.points, tracer);
    let mut solutions = Solutions::default();
    simple_search(&mut state, &mut solutions, &mut constraints);

    solutions.write_one_indexed(&mut out_file)?;
    Ok(())
}
