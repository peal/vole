use tracing::{info, trace_span};

use crate::vole::refiners::{Refiner, Side};
use crate::vole::solutions::Solutions;
use crate::vole::domain_state::DomainState;
use crate::vole::{
    backtracking::{Backtrack, Backtracking},
    partition_stack, trace,
};

pub struct RefinerStore {
    refiners: Vec<Box<dyn Refiner>>,
    base_fixed_values_considered: Backtracking<usize>,
    cells_considered: Backtracking<usize>,
}

impl RefinerStore {
    pub fn new_from_refiners(refiners: Vec<Box<dyn Refiner>>) -> Self {
        Self {
            refiners,
            base_fixed_values_considered: Backtracking::new(0),
            cells_considered: Backtracking::new(0),
        }
    }

    pub fn init_refine(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let span = trace_span!("init_refine:", side = debug(side));
        let _e = span.enter();
        for r in self.refiners.iter_mut() {
            r.refine_begin(state, side)?
        }
        self.do_refine(state, side)
    }

    pub fn do_refine(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let span = trace_span!("do_refine");
        let _e = span.enter();
        loop {
            state.refine_graphs()?;

            let fixed_points = state.partition().base_fixed_values().len();
            assert!(fixed_points >= *self.base_fixed_values_considered);
            if fixed_points > *self.base_fixed_values_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_fixed_points(state, side)?
                }
            }

            // TODO: Check base_fixed_values_considered and cells_considered are updated

            let cells = state.partition().base_cells().len();
            assert!(cells >= *self.cells_considered);
            if cells > *self.cells_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_changed_cells(state, side)?
                }
            }

            if fixed_points == state.partition().base_fixed_values().len()
                && cells == state.partition().base_cells().len()
            {
                // Made no progress
                return Ok(());
            }
        }
    }

    // TODO: This shouldn't be here
    pub fn capture_rbase(&mut self, state: &mut DomainState) {
        assert!(!state.has_rbase());
        state.snapshot_rbase();
    }

    pub fn check_solution(&mut self, state: &mut DomainState, sols: &mut Solutions) -> bool {
        if !state.has_rbase() {
            info!("Taking rbase snapshot");
            state.snapshot_rbase();
        }

        let part = state.partition();
        assert!(part.base_cells().len() == part.base_domain_size());

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
        self.base_fixed_values_considered.save_state();
        self.cells_considered.save_state();
        for c in &mut self.refiners {
            c.save_state();
        }
    }

    fn restore_state(&mut self) {
        self.base_fixed_values_considered.restore_state();
        self.cells_considered.restore_state();
        for c in &mut self.refiners {
            c.restore_state();
        }
    }
}
