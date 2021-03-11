pub mod digraph;
pub mod gaprefiner;
pub mod refiner_store;
pub mod simple;

use crate::perm::Permutation;
use crate::vole::backtracking::Backtrack;
use crate::vole::trace;

use super::state::State;

use serde::Serialize;

#[derive(Debug, Serialize, Clone, Copy)]
pub enum Side {
    Left,
    Right,
}

pub trait Refiner: Backtrack {
    /// A human readable name for the refiner
    fn name(&self) -> String;

    /// Check if this refiner represents a group (as opposed to a coset)
    fn is_group(&self) -> bool;

    /// Check is permutation is in group/coset represented by the refiner
    fn check(&self, p: &Permutation) -> bool;

    fn refine_begin(&mut self, _: &mut State, _: Side) -> trace::Result<()> {
        Ok(())
    }

    fn refine_fixed_points(&mut self, _: &mut State, _: Side) -> trace::Result<()> {
        Ok(())
    }

    fn refine_changed_cells(&mut self, _: &mut State, _: Side) -> trace::Result<()> {
        Ok(())
    }
}
