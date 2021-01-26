use super::refiners::{Refiner, Side};
use super::solutions::Solutions;
use super::state::State;
use super::{
    backtracking::{Backtrack, Backtracking},
    partition_stack, trace,
};

use tracing::{info, trace, trace_span};

pub struct RefinerStore {
    refiners: Vec<Box<dyn Refiner>>,
    fixed_values_considered: Backtracking<usize>,
    cells_considered: Backtracking<usize>,
}

impl RefinerStore {
    pub fn new_from_refiners(refiners: Vec<Box<dyn Refiner>>) -> Self {
        Self {
            refiners,
            fixed_values_considered: Backtracking::new(0),
            cells_considered: Backtracking::new(0),
        }
    }

    pub fn init_refine(&mut self, state: &mut State, side: Side) -> trace::Result<()> {
        let span = trace_span!("init_refine:", side = debug(side));
        let _e = span.enter();
        for r in self.refiners.iter_mut() {
            r.refine_begin(state, side)?
        }
        self.do_refine(state, side)
    }

    pub fn do_refine(&mut self, state: &mut State, side: Side) -> trace::Result<()> {
        let span = trace_span!("do_refine");
        let _e = span.enter();
        loop {
            state.refine_graphs()?;

            let fixed_points = state.partition().fixed_values().len();
            assert!(fixed_points >= *self.fixed_values_considered);
            if fixed_points > *self.fixed_values_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_fixed_points(state, side)?
                }
            }

            let cells = state.partition().cells();
            assert!(cells >= *self.cells_considered);
            if cells > *self.cells_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_changed_cells(state, side)?
                }
            }

            if fixed_points == state.partition().fixed_values().len()
                && cells == state.partition().cells()
            {
                // Made no progress
                return Ok(());
            }
        }
    }

    // TODO: This shouldn't be here
    pub fn capture_rbase(&mut self, state: &mut State) {
        assert!(!state.has_rbase());
        state.snapshot_rbase();
    }

    pub fn check_solution(&mut self, state: &mut State, sols: &mut Solutions) -> bool {
        if !state.has_rbase() {
            info!("Taking rbase snapshot");
            state.snapshot_rbase();
        }

        let part = state.partition();
        assert!(part.cells() == part.domain_size());

        let sol = partition_stack::perm_between(state.rbase_partition(), part);

        let is_sol = self.refiners.iter().all(|x| x.check(&sol));
        if is_sol {
            info!("Found solution: {:?}", sol);
            sols.add(&sol);
        } else {
            info!("Not solution: {:?}", sol);
        }
        is_sol
    }
}

impl Backtrack for RefinerStore {
    fn save_state(&mut self) {
        self.fixed_values_considered.save_state();
        self.cells_considered.save_state();
    }

    fn restore_state(&mut self) {
        self.fixed_values_considered.restore_state();
        self.cells_considered.restore_state();
    }
}

pub fn select_branching_cell(state: &State) -> usize {
    let mut cell = std::usize::MAX;
    let mut cell_size = std::usize::MAX;
    for i in 0..state.partition().cells() {
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
        state.partition().as_list_set()
    );
    cell
}

pub fn build_rbase(state: &mut State, refiners: &mut RefinerStore) {
    let part = state.partition();

    if part.cells() == part.domain_size() {
        refiners.capture_rbase(state);
        return;
    }

    let cell_num = select_branching_cell(state);
    info!("Partition: {:?}", state.partition().as_list_set());
    info!("Branching on {}", cell_num);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    cell.sort();

    let span = trace_span!("B", cell = debug(&cell));
    let _o = span.enter();

    let c = cell[0];

    let span = trace_span!("C", value = c);
    let _o = span.enter();

    state.save_state();

    let cell_count = state.partition().cells();
    if state
        .refine_partition_cell_by(cell_num, |x| *x == c)
        .is_err()
    {
        panic!("RBase Build Failure 1");
    }

    assert!(state.partition().cells() == cell_count + 1);

    if refiners.do_refine(state, Side::Right).is_err() {
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

    if part.cells() == part.domain_size() {
        return refiners.check_solution(state, sols);
    }

    let cell_num = select_branching_cell(state);
    info!("Partition: {:?}", state.partition().as_list_set());
    info!("Branching on {}", cell_num);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    if first_branch_in {
        cell.sort();
    }

    let mut doing_first_branch = first_branch_in;

    let span = trace_span!("B", cell = debug(&cell));
    let _o = span.enter();

    for c in cell {
        let span = trace_span!("C", value = c);
        let _o = span.enter();
        // Skip search if we are in the first branch, not on the first thing, and not min in orbit
        let skip = first_branch_in && !doing_first_branch && !sols.min_in_orbit(c);
        if !skip {
            state.save_state();
            let cell_count = state.partition().cells();
            if state
                .refine_partition_cell_by(cell_num, |x| *x == c)
                .is_ok()
            {
                assert!(state.partition().cells() == cell_count + 1);
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
