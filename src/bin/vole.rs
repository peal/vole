use std::fs::File;

use rust_peal::vole::search::{simple_search, simple_single_search};
use rust_peal::vole::solutions::Solutions;
use rust_peal::vole::state::State;
use rust_peal::vole::trace;
use rust_peal::vole::{parse_input, search::RefinerStore};

use tracing::Level;

use rust_peal::gap_chat::GAP_CHAT;
use tracing_subscriber::fmt::format::FmtSpan;

fn main() -> anyhow::Result<()> {
    // Set up debugging output
    let (non_block, _guard) = tracing_appender::non_blocking(File::create("vole.trace")?);

    tracing_subscriber::fmt()
        .with_span_events(FmtSpan::ACTIVE)
        .with_max_level(Level::TRACE)
        //.pretty()
        .with_writer(non_block)
        .init();

    let problem = parse_input::read_problem(&mut GAP_CHAT.lock().unwrap().in_file)?;

    let mut constraints =
        RefinerStore::new_from_refiners(parse_input::build_constraints(&problem.constraints));
    let tracer = trace::Tracer::new();

    let mut state = State::new(problem.config.points, tracer);
    let mut solutions = Solutions::default();

    if problem.config.find_single {
        simple_single_search(&mut state, &mut solutions, &mut constraints);
    } else {
        simple_search(&mut state, &mut solutions, &mut constraints);
    }

    solutions.write_one_indexed(&mut GAP_CHAT.lock().unwrap().out_file)?;
    Ok(())
}
