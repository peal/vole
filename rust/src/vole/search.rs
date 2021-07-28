use serde::{Deserialize, Serialize};

use crate::vole::subsearch::sub_full_refine;

use super::solutions::SolutionFound;
use super::{backtracking::Backtrack, state::State};
use super::{refiners::Side, selector::select_branching_cell};
use super::{solutions::Solutions, subsearch::sub_simple_search};

use tracing::{info, trace, trace_span};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SearchConfig {
    pub full_graph_refine: bool,
    pub find_single: bool,
}

impl Default for SearchConfig {
    fn default() -> Self {
        Self {
            full_graph_refine: true,
            find_single: false,
        }
    }
}

pub fn build_rbase(state: &mut State, search_config: &SearchConfig) {
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        state.domain.snapshot_rbase(&mut state.refiners);
        return;
    }

    let _span = trace_span!("B").entered();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    cell.sort();

    trace!("On cell: {:?}", debug(&cell));
    let c = cell[0];
    state.domain.push_rbase_branch_val(c);

    let _span = trace_span!("C", value = c).entered();

    state.save_state();

    let cell_count = state.domain.partition().base_cells().len();

    if state.domain.refine_partition_cell_by(cell_num, |x| *x == c).is_err() {
        panic!("RBase Build Failure 1");
    }

    assert!(state.domain.partition().base_cells().len() == cell_count + 1);

    if state
        .refiners
        .do_refine(&mut state.domain, Side::Left, &mut state.stats)
        .is_ok()
        && (!search_config.full_graph_refine || sub_full_refine(state, search_config).is_ok())
    {
        info!("Completed rbase level");
    } else {
        panic!("RBase Build Failure 2");
    }

    build_rbase(state, search_config);

    state.restore_state();
}

fn get_branch_cell(state: &State, to_sort: bool) -> (usize, Vec<usize>) {
    let part = state.domain.partition();

    let cell_num = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();
    assert!(cell.len() > 1);

    if to_sort {
        cell.sort();
    }
    (cell_num, cell)
}

#[must_use]
pub fn simple_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    first_branch_in: bool,
    depth: usize,
    search_config: &SearchConfig,
) -> SolutionFound {
    state.stats.search_nodes += 1;
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        return state.refiners.check_solution(&mut state.domain, sols, &mut state.stats);
    }

    let _span = trace_span!("B").entered();

    let (cell_num, cell) = get_branch_cell(state, first_branch_in);

    let mut doing_first_branch = first_branch_in;

    for c in cell {
        let _span = trace_span!("C", value = c).entered();

        if doing_first_branch && first_branch_in {
            state.domain.push_rbase_branch_val(c);
        }
        let side = if first_branch_in && doing_first_branch {
            Side::Left
        } else {
            Side::Right
        };

        assert!(!(doing_first_branch && !sols.orbit_needs_searching(c, depth)));

        // Skip search if we are in the first branch, not checked anything in this orbit yet, and not on the first thing.
        let skip = first_branch_in && !sols.orbit_needs_searching(c, depth);
        if !skip {
            state.save_state();
            let cell_count = state.domain.partition().base_cells().len();
            info!("Try branching on {:?} in cell {:?}", c, cell_num);
            if state.domain.refine_partition_cell_by(cell_num, |x| *x == c).is_ok() {
                assert!(state.domain.partition().base_cells().len() == cell_count + 1);
                if state
                    .refiners
                    .do_refine(&mut state.domain, side, &mut state.stats)
                    .is_ok()
                    && (!search_config.full_graph_refine || sub_full_refine(state, search_config).is_ok())
                {
                    let ret = simple_search_recurse(state, sols, doing_first_branch, depth + 1, search_config);
                    if !first_branch_in && ret != SolutionFound::None {
                        info!("Backtracking to special node");
                        state.restore_state();
                        return ret;
                    }
                } else {
                    state.stats.trace_fail_nodes += 1;
                }
            } else {
                state.stats.trace_fail_nodes += 1;
            }
            state.restore_state();

            if first_branch_in {
                sols.set_orbit_searched(c, depth);
            }
        }

        doing_first_branch = false;
    }
    SolutionFound::None
}

#[must_use]
pub fn simple_coset_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    depth: usize,
    search_config: &SearchConfig,
) -> SolutionFound {
    state.stats.search_nodes += 1;
    let part = state.domain.partition();

    if part.base_cells().len() == part.base_domain_size() {
        return state.refiners.check_solution(&mut state.domain, sols, &mut state.stats);
    }

    let _span = trace_span!("B").entered();

    let (cell_num, cell) = get_branch_cell(state, false);

    let mut special_node = false;

    for c in cell {
        let _span = trace_span!("C", value = c).entered();

        // Skip search if we are in the first branch, not checked anything in this orbit yet, and not on the first thing.
        let skip = special_node && !sols.orbit_needs_searching(c, depth);
        if !skip {
            state.save_state();
            let cell_count = state.domain.partition().base_cells().len();
            info!("Try branching on {:?} in cell {:?}", c, cell_num);
            if state.domain.refine_partition_cell_by(cell_num, |x| *x == c).is_ok() {
                assert!(state.domain.partition().base_cells().len() == cell_count + 1);
                if state
                    .refiners
                    .do_refine(&mut state.domain, Side::Right, &mut state.stats)
                    .is_ok()
                    && (!search_config.full_graph_refine || sub_full_refine(state, search_config).is_ok())
                {
                    let ret = simple_coset_search_recurse(state, sols, depth + 1, search_config);
                    match ret {
                        SolutionFound::None => {
                            info!("No solution");
                        }
                        SolutionFound::AfterFirst => {
                            if !special_node {
                                info!("Found solution, not a special node");
                                state.restore_state();
                                return ret;
                            }
                        }
                        SolutionFound::First => {
                            info!("Found first solution, marking node as special!");
                            if search_config.find_single {
                                state.restore_state();
                                return ret;
                            } else {
                                assert!(!special_node);
                                special_node = true;
                            }
                        }
                    }
                } else {
                    state.stats.trace_fail_nodes += 1;
                }
            } else {
                state.stats.trace_fail_nodes += 1;
            }
            state.restore_state();

            if special_node {
                sols.set_orbit_searched(c, depth);
            }
        } else {
            info!("Skipping {:?}", c);
        }
    }

    if special_node {
        SolutionFound::First
    } else {
        SolutionFound::None
    }
}
/// Search for a single permutation (for coset intersection)
pub fn simple_coset_search(state: &mut State, sols: &mut Solutions, search_config: &SearchConfig) {
    trace!("Starting Coset Search");

    // First build RBase

    state.save_state();
    if state
        .refiners
        .init_refine(&mut state.domain, Side::Left, &mut state.stats)
        .is_err()
    {
        panic!("RBase Build Failures 0");
    }

    build_rbase(state, search_config);

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
    let _ = simple_coset_search_recurse(state, sols, 0, search_config);
    state.restore_state();
    trace!("Finishing Single Permutation Search");
}

/// Standard complete search, for stabilizer + canonical image
pub fn simple_group_search(state: &mut State, sols: &mut Solutions, search_config: &SearchConfig) {
    trace!("Starting Search");
    let ret = state
        .refiners
        .init_refine(&mut state.domain, Side::Left, &mut state.stats);
    if ret.is_err() {
        return;
    }
    let _ = simple_search_recurse(state, sols, true, 0, search_config);
}

/// Search only the digraph stack created during initalisation
pub fn root_search(state: &mut State, sols: &mut Solutions, search_config: &SearchConfig) {
    if state
        .refiners
        .init_refine(&mut state.domain, Side::Left, &mut state.stats)
        .is_err()
    {
        panic!("RBase Build Failures 0");
    }

    let (ret_sols, _) = sub_simple_search(state, search_config);
    *sols = ret_sols;
}
