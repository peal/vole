pub mod digraph;
pub mod simple;

use crate::perm::FullPermutation;
use crate::trace;

pub trait Refiner<State: super::state::State> {
    fn name(&self) -> String;

    fn check(&self, p: &FullPermutation) -> bool;

    fn refine_begin(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }

    fn refine_fixed_points(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }

    fn refine_changed_cells(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }
}
