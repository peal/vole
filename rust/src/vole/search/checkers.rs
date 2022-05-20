use tracing::info;

use crate::gap_chat::GapChatType;
use crate::perm::Permutation;
use crate::vole::solutions::{Canonical, SolutionFound, Solutions};
use crate::vole::state::State;
use crate::vole::{partition_stack, trace};

/// Check when we reach a candidate solution

/// Check if current DomainState produces a smaller canonical image
pub fn check_canonical(in_state: &mut State, sols: &mut Solutions) {
    let refiners = &mut in_state.refiners;
    let state = &mut in_state.domain;
    let stats = &mut in_state.stats;

    let part = state.partition();
    let pnts = part.base_domain_size();

    // Get canonical permutation
    let preimage: Vec<usize> = part.base_cells().iter().map(|&x| part.cell(x)[0]).collect();
    // GAP needs 1 indexed
    let preimagegap: Vec<usize> = preimage.iter().map(|&x| x + 1).collect();
    let postimagegap: Vec<usize> = GapChatType::send_request(&("canonicalmin", &preimagegap)).unwrap();
    let postimage: Vec<usize> = postimagegap.into_iter().map(|x| x - 1).collect();
    let mut image: Vec<usize> = vec![0; pnts];
    for i in 0..pnts {
        image[preimage[i]] = postimage[i];
    }
    let perm = Permutation::from_vec(image);

    info!("Considering new canonical image: {:?}", perm);

    // If we have found a better trace, then clear the old canonical solution
    if let Some(canonical) = sols.get_canonical() {
        if canonical.trace_version < state.tracer().canonical_trace_version() {
            info!("New canonical trace found, clearing old canonical image");
            sols.set_canonical(None);
        }
    }

    match sols.get_canonical() {
        None => {
            info!("First canonical candidate: {:?}", perm);
            let images = refiners.get_canonical_images(&perm);
            sols.set_canonical(Some(Canonical {
                perm,
                images,
                trace_version: state.tracer().canonical_trace_version(),
            }))
        }
        Some(canonical) => {
            let o = refiners.get_smaller_canonical_image(&perm, &canonical.images, stats);
            if let Some(images) = o {
                info!("Found new canonical image: {:?}", perm);
                sols.set_canonical(Some(Canonical {
                    perm,
                    images,
                    trace_version: state.tracer().canonical_trace_version(),
                }));
            }
        }
    }
}

pub fn check_solution(in_state: &mut State, sols: &mut Solutions) -> SolutionFound {
    let refiners = &mut in_state.refiners;
    let state = &mut in_state.domain;
    let stats = &mut in_state.stats;

    // Make one final 'finish' event on the trace. This avoids problems where one trace
    // is a prefix of another.
    if state.add_trace_event(trace::TraceEvent::EndTrace()).is_err() {
        return SolutionFound::None;
    }
    if !state.has_rbase() {
        info!("Taking rbase snapshot");
        state.snapshot_rbase(refiners);
    }

    let part = state.partition();
    let pnts = part.base_domain_size();
    assert!(part.base_cells().len() == pnts);

    let tracing_type = state.tracer().tracing_type();

    let mut sol_found = SolutionFound::None;
    if tracing_type.contains(trace::TracingType::SYMMETRY) {
        let sol = partition_stack::perm_between(state.rbase_partition().as_ref().unwrap(), part);
        /*
        for r in self.refiners.iter() {
            let x = r.check(&sol);
            let y = r.any_image(&sol, Side::Left);
            let z = r.any_image(&Permutation::id(), Side::Right);
            if x != (r.any_compare(&y, &z) == Ordering::Equal) {
                eprintln!(
                    "\n\n!!!! {:?} {:?} {:?} {:?} {:?} {:?} !!!!\n\n",
                    x,
                    &sol,
                    r.name(),
                    r.any_to_string(&y),
                    r.any_to_string(&z),
                    r.any_compare(&y, &z)
                );
            }

            assert!(
                r.check(&sol)
                    == (r.any_compare(
                        &r.any_image(&sol, Side::Left),
                        &r.any_image(&Permutation::id(), Side::Right)
                    ) == Ordering::Equal)
            );
        }
        */

        let is_sol = refiners.check_all(&sol);
        if is_sol {
            info!("Found solution: {:?}", sol);
            stats.good_iso += 1;
            refiners.iter_mut().for_each(|r| r.solution_found(&sol));
            sol_found = sols.add_solution(&sol);
        } else {
            stats.bad_iso += 1;
            info!("Not solution: {:?}", sol);
        }
    }

    if tracing_type.contains(trace::TracingType::CANONICAL) {
        check_canonical(in_state, sols);
    }

    sol_found
}
