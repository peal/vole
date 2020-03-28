use crate::refiners::Refiner;
use crate::state::State;
use digraph::Digraph;

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

    fn check(&self, p: &perm::Permutation) -> bool {
        (&self.digraph) ^ (&p) == self.digraph
    }

    fn refine_begin(&mut self, state: &mut T) -> trace::Result<()> {
        //  state.refine_partition_by(|x| self.digraph.contains(x))?;
        Ok(())
    }
}
