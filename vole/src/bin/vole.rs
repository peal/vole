extern crate vole;
use crate::vole::refiners::set::SetStabilizer;
use crate::vole::refiners::Refiner;
use crate::vole::state::PartitionState;
use std::collections::HashSet;
use trace::RecordingTracer;
use vole::search::simple_search;

extern crate simplelog;

use simplelog::*;

use std::fs::File;

fn main() -> trace::Result<()> {
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
    let mut refiners: Vec<Box<dyn Refiner<PartitionState<RecordingTracer>>>> =
        vec![Box::new(SetStabilizer::new(set))];
    let tracer = trace::RecordingTracer::new();

    let mut state = PartitionState::new(5, tracer);
    simple_search(&mut state, &mut refiners);
    Ok(())
}
