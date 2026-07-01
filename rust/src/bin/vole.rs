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

use tracing_subscriber::fmt::format::FmtSpan;
use vole::gap_chat::{GapChatType, GAP_CHAT};

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

    // Serve problems until GAP closes the pipe (EOF). A single-shot GAP
    // session closes the pipe after one problem, so we read EOF and exit
    // immediately; a daemon session keeps the pipe open and sends another
    // problem, which we pick up on the next iteration. Every per-problem
    // object below is constructed fresh inside the loop, so nothing leaks
    // between problems. On any error or panic we send the error and exit:
    // an error never leaves a half-consumed daemon stream behind -- the GAP
    // side simply respawns on its next call.
    loop {
    let result = panic::catch_unwind(|| -> Result<bool, anyhow::Error> {
        let problem = match parse_input::read_problem(&mut GAP_CHAT.lock().unwrap().in_file.as_mut().unwrap())? {
            Some(p) => p,
            None => return Ok(false), // EOF: shut down the daemon
        };

        let nonce = problem.nonce;
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
        // The base we hand to GAP (StabChainBaseStrongGenerators) must
        // consist only of base-domain points. A base for the extended
        // graph can live entirely in auxiliary vertices (e.g. the
        // tuple-marker vertex of a set-of-tuples widget pins the whole
        // symmetry on its own), and such a base cannot be repaired by
        // stripping the aux points — it would silently yield a wrong
        // stabiliser chain and group order. Crash rather than return one.
        let base_n = state.domain.partition().base_domain_size();
        assert!(
            state.domain.rbase_branch_vals().iter().all(|&b| b < base_n),
            "rbase branch values must lie in the base domain (got {:?}, base size {})",
            state.domain.rbase_branch_vals(),
            base_n
        );
        // Drop any GapRef-bearing canonical images now, while GAP is still
        // servicing callbacks, so no dropGapRef traffic arrives after the
        // end/goodbye handshake (which would block a reused daemon process).
        solutions.release_images();
        GAP_CHAT.lock().unwrap().send_results(
            nonce,
            &solutions,
            match state.domain.rbase_partition() {
                Some(p) => p.base_fixed_values(),
                None => &[],
            },
            state.domain.rbase_branch_vals(),
            state.stats,
        )?;

        Ok(true) // processed a problem; keep serving
    });

    // Result is a double-nested error (first level panic, second level vole).
    // `Ok(true)` -> processed a problem, loop for the next one.
    // `Ok(false)` -> EOF, shut down. `Err`/panic -> report and shut down.
    match result {
        Ok(Ok(true)) => continue,
        Ok(Ok(false)) => break,
        Ok(Err(e)) => {
            GapChatType::send_error(e.to_string());
            break;
        }
        Err(e) => {
            let s: Box<&'static str> = e.downcast().unwrap();
            GapChatType::send_error(s.to_string());
            break;
        }
    }
    }

    GAP_CHAT.lock().unwrap().close();

    Ok(())
}
