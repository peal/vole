pub mod digraph;
pub mod simple;

use crate::perm::Permutation;
use crate::vole::trace;

pub trait Refiner<State: super::state::State> {
    fn name(&self) -> String;

    // TODO: I would like this to take an arbitrary permutation,
    // but it conflicts with a couple of things (I think maybe a Refiner, RefinerExt pair could solve it)
    fn check(&self, p: &Permutation) -> bool;

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
