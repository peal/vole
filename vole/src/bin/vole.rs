extern crate vole;
use crate::vole::parseinput;

use crate::vole::refiners::Refiner;
use crate::vole::state::PartitionState;

use std::collections::HashSet;
use trace::Tracer;
use vole::search::simple_search;

extern crate simplelog;

use simplelog::*;

use std::path::PathBuf;
use structopt::StructOpt;

use std::{
    fs::File,
    io::{self, BufReader, BufWriter, Write},
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
        TermLogger::new(LevelFilter::Trace, Config::default(), TerminalMode::Mixed).unwrap(),
        WriteLogger::new(
            LevelFilter::Info,
            Config::default(),
            File::create("vole-trace.log").unwrap(),
        ),
    ])
    .unwrap();

    println!("Parsed");

    let mut infile = BufReader::new(unsafe { File::from_raw_fd(opt.inpipe.unwrap()) });
    let mut outfile = BufWriter::new(unsafe { File::from_raw_fd(opt.outpipe.unwrap()) });

    println!("Reading");

    let problem = parseinput::read_problem(&mut infile)?;

    println!("Reading finished");
    /*
    let set: HashSet<usize> = vec![2, 4, 6].into_iter().collect();
    let digraph: Digraph = Digraph::empty(6);
    let mut refiners: Vec<Box<dyn Refiner<PartitionState>>> =
        vec![Box::new(SetStabilizer::new(set)), Box::new(DigraphStabilizer::new(digraph))];
    let tracer = trace::Tracer::new();

    let mut state = PartitionState::new(5, tracer);
    simple_search(&mut state, &mut refiners);
    */
    write!(&mut outfile, "{{\"result\": \"OK\"}}\n")?;
    Ok(())
}
