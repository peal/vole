use std::fs::File;

use rust_vole::vole::solutions::Solutions;
use rust_vole::vole::trace;
use rust_vole::vole::{domain_state::DomainState, trace::TracingType};
use rust_vole::vole::{parse_input, state::State};
use rust_vole::vole::{
    refiners::refiner_store::RefinerStore,
    search::{simple_search, simple_single_search},
};

use tracing::Level;

use rust_vole::gap_chat::GAP_CHAT;
use tracing_subscriber::fmt::format::FmtSpan;

fn main() -> anyhow::Result<()> {
    // Set up debugging output

    let (non_block, _guard) = tracing_appender::non_blocking(File::create("vole.trace")?);

    if rust_vole::gap_chat::OPTIONS.trace {
        tracing_subscriber::fmt()
            .with_span_events(FmtSpan::ACTIVE)
            .with_max_level(Level::TRACE)
            //.with_env_filter("trace,tracer=off")
            .with_ansi(false)
            .without_time()
            //.pretty()
            .with_writer(non_block)
            .init();
    }

    let problem = parse_input::read_problem(&mut GAP_CHAT.lock().unwrap().in_file)?;

    let refiners =
        RefinerStore::new_from_refiners(parse_input::build_constraints(&problem.constraints));

    let tracer = if problem.config.find_canonical {
        trace::Tracer::new()
    } else {
        trace::Tracer::new_with_type(TracingType::SYMMETRY)
    };

    let domain = DomainState::new(problem.config.points, tracer);
    let mut solutions = Solutions::default();

    let mut state = State {
        domain,
        refiners,
        stats: Default::default(),
    };
    if problem.config.find_single {
        simple_single_search(&mut state, &mut solutions);
    } else {
        simple_search(&mut state, &mut solutions);
    }

    GAP_CHAT.lock().unwrap().send_results(
        &solutions,
        state.domain.rbase_partition().base_fixed_values(),
        state.stats,
    )?;

    Ok(())
}
