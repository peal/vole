use super::super::state::State;
use super::Refiner;
use crate::digraph::Digraph;
use crate::perm::FullPermutation;
use crate::trace;

pub struct DigraphStabilizer {
    digraph: Digraph,
}

impl DigraphStabilizer {
    pub fn new(digraph: Digraph) -> DigraphStabilizer {
        DigraphStabilizer { digraph }
    }
}

impl<T: State> Refiner<T> for DigraphStabilizer {
    fn name(&self) -> String {
        format!("DigraphStabilizer of {:?}", self.digraph)
    }

    fn check(&self, p: &FullPermutation) -> bool {
        (&self.digraph) ^ p == self.digraph
    }

    fn refine_begin(&mut self, _state: &mut T) -> trace::Result<()> {
        //  state.refine_partition_by(|x| self.digraph.contains(x))?;
        Ok(())
    }
}
