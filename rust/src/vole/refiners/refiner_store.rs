use std::cmp::Ordering;

use tracing::{info, trace_span};

use crate::vole::trace::TraceEvent;
use crate::vole::{
    backtracking::{Backtrack, Backtracking},
    trace,
};
use crate::vole::{
    refiners::{Refiner, Side},
    stats::Stats,
};
use crate::{perm::Permutation, vole::domain_state::DomainState};

use std::any::Any;

/// Store all refiners, and the current state of the refiners
pub struct RefinerStore {
    /// List of refiners
    refiners: Vec<Box<dyn Refiner>>,
    /// For each refiner, the number of fixed values in the partition the last time the refiner was called
    base_fixed_values_considered: Vec<Backtracking<usize>>,
    /// For each refiner, the number of cells of the partition last time the refiner was called
    cells_considered: Vec<Backtracking<usize>>,
    /// The number of times 'save_state' has been called
    saved_depth: usize,
}

impl RefinerStore {
    /// Create a new RefinerStore from a list of refiners
    pub fn new_from_refiners(refiners: Vec<Box<dyn Refiner>>) -> Self {
        let len = refiners.len();
        Self {
            refiners,
            base_fixed_values_considered: std::iter::repeat_with(|| Backtracking::new(0)).take(len).collect(),
            cells_considered: std::iter::repeat_with(|| Backtracking::new(0)).take(len).collect(),
            saved_depth: 0,
        }
    }

    /// Initialise the refiners
    pub fn init_refine(&mut self, state: &mut DomainState, side: Side, stats: &mut Stats) -> trace::Result<()> {
        let _span = trace_span!("init_refine:", side = debug(side)).entered();
        for (i, r) in self.refiners.iter_mut().enumerate() {
            *self.base_fixed_values_considered[i] = state.partition().base_fixed_values().len();
            *self.cells_considered[i] = state.partition().base_cells().len();
            r.refine_begin(state, side)?;
            stats.refiner_calls += 1;
        }
        self.do_refine(state, side, stats)
    }

    /// Run all refiners, based on changes to the state (assumes init_refine was previously called)
    pub fn do_refine(&mut self, state: &mut DomainState, side: Side, stats: &mut Stats) -> trace::Result<()> {
        let _span = trace_span!("do_refine").entered();
        loop {
            let init_fixed_points = state.partition().base_fixed_values().len();

            for (i, refiner) in self.refiners.iter_mut().enumerate() {
                let fixed_points = state.partition().base_fixed_values().len();
                if fixed_points > *self.base_fixed_values_considered[i] {
                    *self.base_fixed_values_considered[i] = fixed_points;
                    refiner.refine_fixed_points(state, side)?;
                    stats.refiner_calls += 1;
                }
            }

            let init_cells = state.partition().base_cells().len();

            for (i, refiner) in self.refiners.iter_mut().enumerate() {
                let cells = state.partition().base_cells().len();
                if cells > *self.cells_considered[i] {
                    *self.cells_considered[i] = cells;
                    refiner.refine_changed_cells(state, side)?;
                    stats.refiner_calls += 1;
                }
            }

            state.refine_graphs()?;

            if init_fixed_points == state.partition().base_fixed_values().len()
                && init_cells == state.partition().base_cells().len()
            {
                // Made no progress
                state.add_trace_event(TraceEvent::EndRefine())?;
                return Ok(());
            }
        }
    }

    /// Inform all refiners that 'state' is currently the 'rbase', in case they need to store any information
    pub fn snapshot_rbase(&mut self, state: &mut DomainState) {
        for refiner in &mut self.refiners {
            refiner.snapshot_rbase(state);
        }
    }

    /// Get the 'image' of each refiner under the permutation 'p'
    pub fn get_canonical_images(&self, p: &Permutation) -> Vec<Box<dyn Any>> {
        return self.refiners.iter().map(|r| r.any_image(p, Side::Left)).collect();
    }

    /// Check if applying 'p' produces a small image than 'prev'.
    pub fn get_smaller_canonical_image(
        &self,
        p: &Permutation,
        prev: &[Box<dyn Any>],
        stats: &mut Stats,
    ) -> Option<Vec<Box<dyn Any>>> {
        // TODO: Speed up
        let image = self.get_canonical_images(p);
        let len = image.len();
        info!(
            "Comparing Canonical. prev: {:?} image: {:?}",
            (0..len)
                .map(|i| self.refiners[i].any_to_string(&prev[i]))
                .collect::<Vec<_>>(),
            (0..len)
                .map(|i| self.refiners[i].any_to_string(&image[i]))
                .collect::<Vec<_>>()
        );
        for i in 0..prev.len() {
            let ord = self.refiners[i].any_compare(&image[i], &prev[i]);
            match ord {
                std::cmp::Ordering::Less => {
                    info!("Improved Canonical");
                    stats.improve_canonical += 1;
                    return Some(image);
                }
                std::cmp::Ordering::Equal => {}
                std::cmp::Ordering::Greater => {
                    info!("Worse Canonical");
                    stats.bad_canonical += 1;
                    return None;
                }
            }
        }
        info!("Found identical canonical image");
        stats.equal_canonical += 1;
        None
    }

    pub fn check_all(&self, p: &Permutation) -> bool {
        // This line checks that the 'check' function, cand the canonical image code, agree
        debug_assert!(self.refiners.iter().all(|x| x.check(p)
            == (x.any_compare(
                &x.any_image(p, Side::Left),
                &x.any_image(&Permutation::id(), Side::Right)
            ) == Ordering::Equal)));

        self.refiners.iter().all(|x| x.check(p))
    }
}

impl Backtrack for RefinerStore {
    fn save_state(&mut self) {
        for v in &mut self.base_fixed_values_considered {
            v.save_state();
        }
        for v in &mut self.cells_considered {
            v.save_state();
        }
        for c in &mut self.refiners {
            c.save_state();
        }

        self.saved_depth += 1;
    }

    fn restore_state(&mut self) {
        for v in &mut self.base_fixed_values_considered {
            v.restore_state();
        }
        for v in &mut self.cells_considered {
            v.restore_state();
        }
        for c in &mut self.refiners {
            c.restore_state();
        }
        self.saved_depth -= 1;
    }

    fn state_depth(&self) -> usize {
        debug_assert!(self
            .base_fixed_values_considered
            .iter()
            .all(|v| v.state_depth() == self.saved_depth));
        debug_assert!(self
            .cells_considered
            .iter()
            .all(|v| v.state_depth() == self.saved_depth));
        self.saved_depth
    }
}
