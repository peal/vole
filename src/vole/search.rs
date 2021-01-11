use super::refiners::Refiner;
use super::solutions::Solutions;
use super::state::State;
use super::{
    backtracking::{Backtrack, Backtracking},
    partition_stack, trace,
};

use tracing::{info, trace, trace_span};

pub struct RefinerStore<T: State> {
    refiners: Vec<Box<dyn Refiner<T>>>,
    fixed_values_considered: Backtracking<usize>,
    cells_considered: Backtracking<usize>,
}

impl<T: State> RefinerStore<T> {
    pub fn new_from_refiners(refiners: Vec<Box<dyn Refiner<T>>>) -> Self {
        Self {
            refiners,
            fixed_values_considered: Backtracking::new(0),
            cells_considered: Backtracking::new(0),
        }
    }

    pub fn init_refine(&mut self, state: &mut T) -> trace::Result<()> {
        let span = trace_span!("init_refine");
        let _e = span.enter();
        for r in self.refiners.iter_mut() {
            r.refine_begin_left(state)?
        }
        self.do_refine(state)
    }

    pub fn do_refine(&mut self, state: &mut T) -> trace::Result<()> {
        let span = trace_span!("do_refine");
        let _e = span.enter();
        loop {
            state.refine_graphs()?;

            let fixed_points = state.partition().fixed_values().len();
            assert!(fixed_points >= *self.fixed_values_considered);
            if fixed_points > *self.fixed_values_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_fixed_points_left(state)?
                }
            }

            let cells = state.partition().cells();
            assert!(cells >= *self.cells_considered);
            if cells > *self.cells_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_changed_cells_left(state)?
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

    pub fn check_solution(&mut self, state: &mut T, sols: &mut Solutions) -> bool {
        if !state.has_rbase() {
            info!("Taking rbase snapshot");
            state.snapshot_rbase();
        }

        let part = state.partition();
        assert!(part.cells() == part.domain_size());

        let sol = partition_stack::perm_between(state.rbase_partition(), part);

        info!("Checking solution: {:?}", sol);

        let is_sol = self.refiners.iter().all(|x| x.check(&sol));
        if is_sol {
            info!("Found solution");
            sols.add(&sol);
        } else {
            info!("Not solution");
        }
        is_sol
    }
}

impl<T: State> Backtrack for RefinerStore<T> {
    fn save_state(&mut self) {
        self.fixed_values_considered.save_state();
        self.cells_considered.save_state();
    }

    fn restore_state(&mut self) {
        self.fixed_values_considered.restore_state();
        self.cells_considered.restore_state();
    }
}

pub fn select_branching_cell<T: State>(state: &T) -> usize {
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

pub fn simple_search_recurse<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut RefinerStore<T>,
    first_branch_in: bool,
) {
    let part = state.partition();

    if part.cells() == part.domain_size() {
        if refiners.check_solution(state, sols) {}
        return;
    }

    let cell_num = select_branching_cell(state);
    info!("Partition: {:?}", state.partition().as_list_set());
    info!("Branching on {}", cell_num);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();

    if first_branch_in {
        cell.sort();
    }

    let mut doing_first_branch = first_branch_in;
    for c in cell {
        // Skip search if we are in the first branch, not on the first thing, and not min in orbit
        let skip = first_branch_in && !doing_first_branch && !sols.min_in_orbit(c);
        if !skip {
            state.save_state();
            if state
                .refine_partition_cell_by(cell_num, |x| *x == c)
                .is_ok()
                && refiners.do_refine(state).is_ok()
            {
                simple_search_recurse(state, sols, refiners, doing_first_branch);
            }
            state.restore_state();
        }
        doing_first_branch = false;
    }
    info!("Returning");
}

pub fn simple_search<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut RefinerStore<T>,
) {
    trace!("CHECK");
    let ret = refiners.init_refine(state);
    if ret.is_err() {
        return;
    }
    simple_search_recurse(state, sols, refiners, true);
}
