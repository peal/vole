use std::hash::Hash;

use crate::vole::trace;
use crate::{
    datastructures::digraph::{Digraph, DigraphStack},
    vole::partition_stack,
};

use crate::vole::backtracking::Backtrack;

pub trait State: Backtrack {
    fn partition(&self) -> &partition_stack::PartitionStack;

    fn has_rbase(&self) -> bool;
    fn snapshot_rbase(&mut self);
    fn rbase_partition(&self) -> &partition_stack::PartitionStack;

    fn refine_partition_cell_by<F: Copy, T: Ord + Hash>(
        &mut self,
        i: usize,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> T;
    fn refine_partition_by<F: Copy, T: Ord + Hash>(&mut self, f: F) -> trace::Result<()>
    where
        F: Fn(&usize) -> T;

    fn add_graph(&mut self, dgraph: &Digraph);
    fn add_graphs(&mut self, dgraphs: &[Digraph]);
}

pub struct PartitionState {
    stack: partition_stack::PartitionStack,
    rbasestack: Option<partition_stack::PartitionStack>,
    tracer: trace::Tracer,
    digraph_stack: DigraphStack,
}

impl PartitionState {
    pub fn new(n: usize, t: trace::Tracer) -> Self {
        Self {
            stack: partition_stack::PartitionStack::new(n),
            rbasestack: Option::None,
            tracer: t,
            digraph_stack: DigraphStack::empty(n),
        }
    }
}

impl State for PartitionState {
    fn partition(&self) -> &partition_stack::PartitionStack {
        &self.stack
    }

    fn has_rbase(&self) -> bool {
        self.rbasestack.is_some()
    }
    fn snapshot_rbase(&mut self) {
        assert!(self.rbasestack.is_none());
        self.rbasestack = Some(self.stack.clone());
    }

    fn rbase_partition(&self) -> &partition_stack::PartitionStack {
        self.rbasestack.as_ref().unwrap()
    }

    fn refine_partition_cell_by<F: Copy, T: Ord + Hash>(
        &mut self,
        i: usize,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> T,
    {
        self.stack.refine_partition_cell_by(&mut self.tracer, i, f)
    }

    fn refine_partition_by<F: Copy, T: Ord + Hash>(&mut self, f: F) -> trace::Result<()>
    where
        F: Fn(&usize) -> T,
    {
        self.stack.refine_partition_by(&mut self.tracer, f)
    }

    fn add_graph(&mut self, d: &Digraph) {
        self.digraph_stack.add_graph(d);
    }

    fn add_graphs(&mut self, dgraphs: &[Digraph]) {
        self.digraph_stack.add_graphs(dgraphs);
    }
}

impl Backtrack for PartitionState {
    fn save_state(&mut self) {
        self.stack.save_state();
        self.digraph_stack.save_state();
    }

    fn restore_state(&mut self) {
        self.stack.restore_state();
        self.digraph_stack.restore_state();
    }
}
