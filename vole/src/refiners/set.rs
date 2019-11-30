use crate::refiners::Refiner;
use crate::state::State;
use std::collections::HashSet;

struct SetStabilizer {
    set: HashSet<usize>,
}

impl<T:State> Refiner<T> for SetStabilizer {
    fn name(&self) -> String {
        format!("SetStabilizer of {:?}", self.set)
    }

    fn check(&self, p: &perm::Permutation) -> bool {
        self.set
            .iter()
            .cloned()
            .all(|x| self.set.contains(&(x ^ p)))
    }

    fn refine_begin(&mut self, state: &mut T) -> trace::Result<()> {
        state.refine_partition_by(|x| self.set.contains(x))?;
        Ok(())
    }
}
