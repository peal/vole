mod checkers;

use serde::{Deserialize, Serialize};

use crate::vole::subsearch::sub_full_refine;

use super::solutions::SolutionFound;
use super::{backtracking::Backtrack, state::State};
use super::{refiners::Side, selector::select_branching_cell};
use super::{solutions::Solutions, subsearch::sub_simple_search};

use tracing::{info, trace, trace_span};

/// This contains config for the search which is not expected to change during search
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SearchConfig {
    pub full_graph_refine: bool,
    find_single: bool,
    /// If true, the search treats the "canonical group" as the full
    /// symmetric group on the domain — meaning the canonical-minimum
    /// of any tuple under the canonical group is just the sorted form
    /// `[0..k-1]`. This lets `check_canonical` skip the GAP round-trip
    /// for the canonicalmin request entirely.
    ///
    /// Set true by `sub_full_refine` for its sub-search, where the
    /// natural canonical context is always `Sym(sub_domain)`, and the
    /// sub-search must not call back into GAP (its outer GAP session
    /// holds a different canonicalgroup binding and has no protocol
    /// for sub-search-scoped canonicalmin requests). See also the
    /// guard at `gap_chat.rs` that panics if a GAP callback fires
    /// during a sub-search.
    #[serde(default)]
    pub canonical_min_trivial: bool,
}

impl Default for SearchConfig {
    fn default() -> Self {
        Self {
            full_graph_refine: true,
            find_single: false,
            canonical_min_trivial: false,
        }
    }
}

fn build_rbase(state: &mut State, search_config: &SearchConfig) {
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
fn simple_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    first_branch_in: bool,
    depth: usize,
    search_config: &SearchConfig,
) -> SolutionFound {
    state.stats.search_nodes += 1;
    let part = state.domain.partition();

    if part.base_domain_fixed() {
        return checkers::check_solution(state, sols, search_config);
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
fn simple_coset_search_recurse(
    state: &mut State,
    sols: &mut Solutions,
    depth: usize,
    search_config: &SearchConfig,
) -> SolutionFound {
    state.stats.search_nodes += 1;
    let part = state.domain.partition();

    if part.base_domain_fixed() {
        return checkers::check_solution(state, sols, search_config);
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

#[cfg(test)]
mod fgr_tests {
    use std::sync::Arc;

    use crate::datastructures::digraph::Digraph;
    use crate::perm::Permutation;
    use crate::vole::{
        domain_state::DomainState,
        refiners::{digraph::DigraphTransporter, refiner_store::RefinerStore, Refiner},
        solutions::Solutions,
        state::State,
        trace::{self, TracingType},
    };

    use super::{simple_group_search, SearchConfig};

    /// Enumerate the closure of a list of permutations under composition
    /// (orbit of the identity). For checking that a found set of
    /// strong generators actually generates the expected group.
    fn group_order(gens: &[Permutation]) -> usize {
        let mut elements = vec![Permutation::id()];
        let mut frontier = vec![Permutation::id()];
        while let Some(p) = frontier.pop() {
            for g in gens {
                let q = p.multiply(g);
                if !elements.iter().any(|e| e == &q) {
                    elements.push(q.clone());
                    frontier.push(q);
                }
            }
        }
        elements.len()
    }

    /// Build a State stabilising `digraph` on `n` points and run
    /// simple_group_search with the given full_graph_refine flag.
    /// Returns the order of the group generated by the strong
    /// generators found (computed by closure under composition).
    fn stab_search_order(digraph: Digraph, n: usize, full_graph_refine: bool) -> usize {
        // BOTH tracing — the same as production calls from GAP.
        // canonical_min_trivial = true lets the canonical-image
        // path short-circuit locally instead of calling GAP_CHAT.
        let refiner: Box<dyn Refiner> =
            Box::new(DigraphTransporter::new_stabilizer(Arc::new(digraph)));
        let refiners = RefinerStore::new_from_refiners(vec![refiner]);
        let tracer = trace::Tracer::new_with_type(TracingType::BOTH);
        let domain = DomainState::new(n, tracer);
        let mut state = State {
            domain,
            refiners,
            stats: Default::default(),
        };
        let mut sols = Solutions::new(n);
        let config = SearchConfig {
            full_graph_refine,
            canonical_min_trivial: true,
            ..SearchConfig::default()
        };
        simple_group_search(&mut state, &mut sols, &config);
        group_order(sols.get())
    }

    /// Aut(directed 3-cycle 0->1->2->0) = C_3, order 3.
    #[test]
    fn single_3cycle_fgr_off() {
        let d = Digraph::from_vec(vec![vec![1], vec![2], vec![0]]);
        assert_eq!(stab_search_order(d, 3, false), 3);
    }

    #[test]
    fn single_3cycle_fgr_on() {
        let d = Digraph::from_vec(vec![vec![1], vec![2], vec![0]]);
        assert_eq!(stab_search_order(d, 3, true), 3);
    }

    /// Aut(two disjoint directed 3-cycles) = C_3 ≀ S_2, order 18.
    /// The case where FGR with identity canonicalmin gave wrong answers
    /// from GAP ((C_3)^2 came back as size 4 instead of 72 normaliser
    /// — same shape of failure).
    #[test]
    fn two_3cycles_fgr_off() {
        let d = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![4], vec![5], vec![3]]);
        assert_eq!(stab_search_order(d, 6, false), 18);
    }

    #[test]
    fn two_3cycles_fgr_on() {
        let d = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![4], vec![5], vec![3]]);
        assert_eq!(stab_search_order(d, 6, true), 18);
    }

    /// Aut(two disjoint directed 5-cycles) = C_5 ≀ S_2, order 50.
    /// (C_5)^2 was the input where FGR hung indefinitely from GAP.
    #[test]
    fn two_5cycles_fgr_off() {
        let d = Digraph::from_vec(vec![
            vec![1], vec![2], vec![3], vec![4], vec![0],
            vec![6], vec![7], vec![8], vec![9], vec![5],
        ]);
        assert_eq!(stab_search_order(d, 10, false), 50);
    }

    #[test]
    fn two_5cycles_fgr_on() {
        let d = Digraph::from_vec(vec![
            vec![1], vec![2], vec![3], vec![4], vec![0],
            vec![6], vec![7], vec![8], vec![9], vec![5],
        ]);
        assert_eq!(stab_search_order(d, 10, true), 50);
    }
}
