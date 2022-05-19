use std::fs::File;

use anyhow::bail;
use cpu_time::ProcessTime;
use vole::vole::trace;
use vole::vole::{domain_state::DomainState, trace::TracingType};
use vole::vole::{parse_input, state::State};
use vole::vole::{
    refiners::refiner_store::RefinerStore,
    search::{simple_coset_search, simple_group_search},
};
use vole::vole::{search::root_search, solutions::Solutions};

use tracing::Level;

use vole::gap_chat::{GapChatType, GAP_CHAT};
use tracing_subscriber::fmt::format::FmtSpan;

use std::panic;

fn main() -> anyhow::Result<()> {
    // Set up debugging output

    let (non_block, _guard) = tracing_appender::non_blocking(File::create("vole.trace")?);

    if vole::gap_chat::OPTIONS.trace {
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

    // Hide panic messages, if we are not tracing
    if vole::gap_chat::OPTIONS.quiet {
        panic::set_hook(Box::new(|_| {}));
    }

    let result = panic::catch_unwind(|| -> Result<(), anyhow::Error> {
        let problem = parse_input::read_problem(&mut GAP_CHAT.lock().unwrap().in_file.as_mut().unwrap())?;

        let refiners = RefinerStore::new_from_refiners(parse_input::build_constraints(&problem.constraints));

        let tracer = if problem.config.find_canonical {
            trace::Tracer::new()
        } else {
            trace::Tracer::new_with_type(TracingType::SYMMETRY)
        };

        let domain = DomainState::new(problem.config.points, tracer);
        let mut solutions = Solutions::new(problem.config.points);

        let mut state = State {
            domain,
            refiners,
            stats: Default::default(),
        };

        if problem.config.find_coset && problem.config.find_canonical {
            bail!("Cannot find coset, and canonical, at the same time");
        }

        if problem.config.root_search {
            root_search(&mut state, &mut solutions, &problem.config.search_config);
        } else if problem.config.find_coset {
            simple_coset_search(&mut state, &mut solutions, &problem.config.search_config);
        } else {
            simple_group_search(&mut state, &mut solutions, &problem.config.search_config);
        }

        if let Ok(time) = ProcessTime::try_now() {
            state.stats.vole_time = time.as_duration().as_millis();
        }
        GAP_CHAT.lock().unwrap().send_results(
            &solutions,
            match state.domain.rbase_partition() {
                Some(p) => p.base_fixed_values(),
                None => &[],
            },
            state.domain.rbase_branch_vals(),
            state.stats,
        )?;

        Ok(())
    });

    // Result is a double-nested error (first level panic, second level vole)
    match result {
        Ok(m) => match m {
            Ok(()) => {}
            Err(e) => {
                GapChatType::send_error(e.to_string());
            }
        },
        Err(e) => {
            let s: Box<&'static str> = e.downcast().unwrap();
            GapChatType::send_error(s.to_string());
        }
    }

    GAP_CHAT.lock().unwrap().close();

    Ok(())
}
