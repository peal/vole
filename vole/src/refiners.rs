mod graph;
mod set;

pub trait Refiner<State> {
    fn name(&self) -> String;

    fn check(&self, p: &perm::Permutation) -> bool;

    fn prop_initalise(&mut self, _: &State) -> Result<(),()>
    { Ok(()) }

    fn prop_fixed_points(&mut self, _: &State) -> Result<(),()>
    { Ok(()) }

    fn prop_changed_cells(&mut self, _: &State) -> Result<(),()>
    { Ok(()) }
}
