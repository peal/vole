pub mod graph;
pub mod set;

pub trait Refiner<State: crate::state::State> {
    fn name(&self) -> String;

    fn check(&self, p: &perm::Permutation) -> bool;

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
