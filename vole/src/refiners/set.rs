use std::collections::HashSet;
use crate::refiners::Refiner;

struct SetStabilizer
{
    set : HashSet<usize>
}

impl<T> Refiner<T> for SetStabilizer {
    fn name(&self) -> String {
        format!("SetStabilizer of {:?}", self.set)
    }

    fn check(&self, p :&perm::Permutation) -> bool {
        self.set.iter().cloned().all(|x| self.set.contains(&(x^p)))
}
}