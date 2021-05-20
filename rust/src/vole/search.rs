use super::solutions::Solutions;
use super::{backtracking::Backtrack, state::State};
use super::{refiners::Side, selector::select_branching_cell};

use tracing::{info, trace, trace_span};

pub fn build_rbase(state: &mut State) {
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        state.domain.snapshot_rbase();
        return;
    }

    let span = trace_span!("B");
    let _o = span.enter();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    cell.sort();

    trace!("On cell: {:?}", debug(&cell));
    let c = cell[0];
    state.domain.push_rbase_branch_val(c);

    let span = trace_span!("C", value = c);
    let _o = span.enter();

    state.save_state();

    let cell_count = state.domain.partition().base_cells().len();

    if state
        .domain
        .refine_partition_cell_by(cell_num, |x| *x == c)
        .is_err()
    {
        panic!("RBase Build Failure 1");
    }

    assert!(state.domain.partition().base_cells().len() == cell_count + 1);

    if state
        .refiners
        .do_refine(&mut state.domain, Side::Left, &mut state.stats)
        .is_err()
    {
        panic!("RBase Build Failure 2");
    }

    build_rbase(state);

    state.restore_state();
}

#[must_use]
pub fn simple_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    first_branch_in: bool,
) -> bool {
    state.stats.search_nodes += 1;
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        return state
            .refiners
            .check_solution(&mut state.domain, sols, &mut state.stats);
    }

    let span = trace_span!("B");
    let _o = span.enter();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();
    assert!(cell.len() > 1);

    if first_branch_in {
        cell.sort();
    }

    let mut doing_first_branch = first_branch_in;

    for c in cell {
        let span = trace_span!("C", value = c);
        let _o = span.enter();
        if doing_first_branch && first_branch_in {
            state.domain.push_rbase_branch_val(c);
        }
        // Skip search if we are in the first branch, not on the first thing, and not min in orbit
        let skip = first_branch_in && !doing_first_branch && !sols.min_in_orbit(c);
        if !skip {
            state.save_state();
            let cell_count = state.domain.partition().base_cells().len();
            info!("Try branching on {:?} in cell {:?}", c, cell_num);
            if state
                .domain
                .refine_partition_cell_by(cell_num, |x| *x == c)
                .is_ok()
            {
                assert!(state.domain.partition().base_cells().len() == cell_count + 1);
                info!("Run refiners");
                if state
                    .refiners
                    .do_refine(&mut state.domain, Side::Right, &mut state.stats)
                    .is_ok()
                {
                    let ret = simple_search_recurse(state, sols, doing_first_branch);
                    if !first_branch_in && ret {
                        info!("Backtracking to special node");
                        state.restore_state();
                        return true;
                    }
                } else {
                    state.stats.trace_fail_nodes += 1;
                }
            } else {
                state.stats.trace_fail_nodes += 1;
            }
            state.restore_state();
        }
        doing_first_branch = false;
    }
    false
}

pub fn simple_single_search(state: &mut State, sols: &mut Solutions) {
    trace!("Starting Single Permutation Search");

    // First build RBase

    state.save_state();
    if state
        .refiners
        .init_refine(&mut state.domain, Side::Left, &mut state.stats)
        .is_err()
    {
        panic!("RBase Build Failures 0");
    }

    build_rbase(state);

    state.restore_state();

    trace!("RBase Built");

    // Now do search
    state.save_state();

    let ret = state
        .refiners
        .init_refine(&mut state.domain, Side::Right, &mut state.stats);
    if ret.is_err() {
        return;
    }
    let _ = simple_search_recurse(state, sols, false);
    state.restore_state();
}

pub fn simple_search(state: &mut State, sols: &mut Solutions) {
    trace!("Starting Search");
    let ret = state
        .refiners
        .init_refine(&mut state.domain, Side::Left, &mut state.stats);
    if ret.is_err() {
        return;
    }
    let _ = simple_search_recurse(state, sols, true);
}
