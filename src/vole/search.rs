use super::backtracking::Backtrack;
use super::refiners::{refiner_store::RefinerStore, Side};
use super::solutions::Solutions;
use super::state::State;

use tracing::{info, trace, trace_span};

pub fn select_branching_cell(state: &State) -> usize {
    let mut cell = std::usize::MAX;
    let mut cell_size = std::usize::MAX;
    for &i in state.partition().base_cells() {
        let size = state.partition().cell(i).len();
        if size < cell_size && size > 1 {
            cell = i;
            cell_size = state.partition().cell(i).len();
        }
    }
    assert_ne!(cell, std::usize::MAX);
    info!(
        "Choosing to branch on cell {:?} from {:?}",
        cell,
        state.partition().extended_as_list_set()
    );
    cell
}

pub fn build_rbase(state: &mut State, refiners: &mut RefinerStore) {
    let part = state.partition();

    if part.base_cells().len() == part.base_domain_size() {
        refiners.capture_rbase(state);
        return;
    }

    let span = trace_span!("B");
    let _o = span.enter();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    cell.sort();

    trace!("On cell: {:?}", debug(&cell));
    let c = cell[0];

    let span = trace_span!("C", value = c);
    let _o = span.enter();

    state.save_state();

    let cell_count = state.partition().base_cells().len();

    if state
        .refine_partition_cell_by(cell_num, |x| *x == c)
        .is_err()
    {
        panic!("RBase Build Failure 1");
    }

    assert!(state.partition().base_cells().len() == cell_count + 1);

    if refiners.do_refine(state, Side::Left).is_err() {
        panic!("RBase Build Failure 2");
    }

    build_rbase(state, refiners);

    state.restore_state();
}

#[must_use]
pub fn simple_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    refiners: &mut RefinerStore,
    first_branch_in: bool,
) -> bool {
    let part = state.partition();

    if part.base_cells().len() == part.base_domain_size() {
        return refiners.check_solution(state, sols);
    }

    let span = trace_span!("B");
    let _o = span.enter();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    if first_branch_in {
        cell.sort();
    }

    let mut doing_first_branch = first_branch_in;

    for c in cell {
        let span = trace_span!("C", value = c);
        let _o = span.enter();
        // Skip search if we are in the first branch, not on the first thing, and not min in orbit
        let skip = first_branch_in && !doing_first_branch && !sols.min_in_orbit(c);
        if !skip {
            state.save_state();
            let cell_count = state.partition().base_cells().len();
            if state
                .refine_partition_cell_by(cell_num, |x| *x == c)
                .is_ok()
            {
                assert!(state.partition().base_cells().len() == cell_count + 1);
                if refiners.do_refine(state, Side::Right).is_ok() {
                    let ret = simple_search_recurse(state, sols, refiners, doing_first_branch);
                    if !first_branch_in && ret {
                        info!("Backtracking to special node");
                        state.restore_state();
                        return true;
                    }
                }
            }
            state.restore_state();
        }
        doing_first_branch = false;
    }
    false
}

pub fn simple_single_search(state: &mut State, sols: &mut Solutions, refiners: &mut RefinerStore) {
    trace!("Starting Single Permutation Search");

    // First build RBase

    state.save_state();
    if refiners.init_refine(state, Side::Left).is_err() {
        panic!("RBase Build Failures 0");
    }

    build_rbase(state, refiners);

    state.restore_state();

    trace!("RBase Built");

    // Now do search
    state.save_state();

    let ret = refiners.init_refine(state, Side::Right);
    if ret.is_err() {
        return;
    }
    let _ = simple_search_recurse(state, sols, refiners, false);
    state.restore_state();
}

pub fn simple_search(state: &mut State, sols: &mut Solutions, refiners: &mut RefinerStore) {
    trace!("Starting Search");
    let ret = refiners.init_refine(state, Side::Right);
    if ret.is_err() {
        return;
    }
    let _ = simple_search_recurse(state, sols, refiners, true);
}
