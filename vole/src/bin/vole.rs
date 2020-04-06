extern crate vole;
use crate::vole::parseinput;
use crate::vole::solutions::Solutions;
use crate::vole::state::PartitionState;
extern crate simplelog;

use vole::search::simple_search;

use simplelog::*;

extern crate serde_json;

use std::path::PathBuf;
use structopt::StructOpt;

use std::{
    fs::File,
    io::{BufReader, BufWriter},
    os::unix::io::FromRawFd,
};

#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    #[structopt(short, long)]
    pub inpipe: Option<i32>,
    #[structopt(short, long)]
    pub outpipe: Option<i32>,
    /// Output file
    #[structopt(short, long, parse(from_os_str))]
    pub file: Option<PathBuf>,

    #[structopt(short, long)]
    pub trace: bool,
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

    let mut infile = BufReader::new(unsafe { File::from_raw_fd(opt.inpipe.unwrap()) });
    let mut outfile = BufWriter::new(unsafe { File::from_raw_fd(opt.outpipe.unwrap()) });

    let problem = parseinput::read_problem(&mut infile)?;

    let mut constraints = parseinput::build_constraints(&problem.constraints);
    let tracer = trace::Tracer::new();

    let mut state = PartitionState::new(problem.config.points, tracer);
    let mut solutions = Solutions::default();
    simple_search(&mut state, &mut solutions, &mut constraints);

    solutions.write_one_indexed(&mut outfile)?;
    Ok(())
}
