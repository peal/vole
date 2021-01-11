use super::super::state::State;
use super::Refiner;
use crate::perm::Permutation;
use crate::vole::trace;
use crate::{datastructures::digraph::Digraph, vole::backtracking::Backtrack};

pub struct DigraphStabilizer {
    digraph: Digraph,
}

impl DigraphStabilizer {
    pub fn new(digraph: Digraph) -> Self {
        Self { digraph }
    }
}

impl Refiner for DigraphStabilizer {
    fn name(&self) -> String {
        format!("DigraphStabilizer of {:?}", self.digraph)
    }

    fn check(&self, p: &Permutation) -> bool {
        (&self.digraph) ^ p == self.digraph
    }

    fn refine_begin_left(&mut self, state: &mut State) -> trace::Result<()> {
        state.add_graph(&self.digraph);
        Ok(())
    }

    fn is_group(&self) -> bool {
        true
    }
}

impl Backtrack for DigraphStabilizer {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}
