use super::refiners::Side;
use super::solutions::Solutions;
use super::{backtracking::Backtrack, state::State};

use tracing::{info, trace, trace_span};

pub fn select_branching_cell(state: &State) -> usize {
    let part = state.domain.partition();
    let mut cell = std::usize::MAX;
    let mut cell_size = std::usize::MAX;
    for &i in part.base_cells() {
        let size = part.cell(i).len();
        if size < cell_size && size > 1 {
            cell = i;
            cell_size = part.cell(i).len();
        }
    }
    assert_ne!(cell, std::usize::MAX);
    info!(
        "Choosing to branch on cell {:?} from {:?}",
        cell,
        part.extended_as_list_set()
    );
    cell
}

pub fn build_rbase(state: &mut State) {
    state.stats.rbase_nodes += 1;
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        state.refiners.capture_rbase(&mut state.domain);
        return;
    }

    let span = trace_span!("B");
    let _o = span.enter();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    cell.sort();

    trace!("On cell: {:?}", debug(&cell));
    let c = cell[0];
    state.stats.rbase_branch_vals.push(c);

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
                }
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
