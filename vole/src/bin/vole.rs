extern crate vole;
use crate::vole::refiners::set::SetStabilizer;
use crate::vole::refiners::digraph::DigraphStabilizer;
use crate::vole::refiners::Refiner;
use crate::vole::state::PartitionState;
use std::collections::HashSet;
use trace::RecordingTracer;
use digraph::Digraph;
use vole::search::simple_search;

extern crate simplelog;

use simplelog::*;

use std::fs::File;

use std::path::PathBuf;
use structopt::StructOpt;

#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
pub struct Opt {
    #[structopt(short, long)]
    pub inpipe: Option<u16>,
    #[structopt(short, long)]
    pub outpipe: Option<u16>,
    /// Output file
    #[structopt(short, long, parse(from_os_str))]
    pub file: Option<PathBuf>,

    #[structopt(short, long)]
    pub trace: bool
}


fn main() -> trace::Result<()> {
    let _opt = Opt::from_args();

    CombinedLogger::init(vec![
        TermLogger::new(LevelFilter::Trace, Config::default(), TerminalMode::Mixed).unwrap(),
        WriteLogger::new(
            LevelFilter::Info,
            Config::default(),
            File::create("vole-trace.log").unwrap(),
        ),
    ])
    .unwrap();

    let set: HashSet<usize> = vec![2, 4, 6].into_iter().collect();
    let digraph: Digraph = Digraph::empty(6);
    let mut refiners: Vec<Box<dyn Refiner<PartitionState<RecordingTracer>>>> =
        vec![Box::new(SetStabilizer::new(set)), Box::new(DigraphStabilizer::new(digraph))];
    let tracer = trace::RecordingTracer::new();

    let mut state = PartitionState::new(5, tracer);
    simple_search(&mut state, &mut refiners);
    Ok(())
}
