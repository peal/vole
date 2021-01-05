use std::hash::Hash;

use tracing::info;

use crate::vole::trace;
use crate::{
    datastructures::digraph::{Digraph, DigraphStack},
    vole::partition_stack,
};

use crate::vole::backtracking::Backtrack;

use super::backtracking::Backtracking;

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

    fn add_graph(&mut self, digraph: &Digraph);
    fn add_graphs(&mut self, digraphs: &[Digraph]);

    fn refine_graphs(&mut self) -> trace::Result<()>;
}

pub struct PartitionState {
    stack: partition_stack::PartitionStack,
    rbase_stack: Option<partition_stack::PartitionStack>,
    tracer: trace::Tracer,
    digraph_stack: DigraphStack,
    digraph_stack_cells_refined: Backtracking<usize>,
}

impl PartitionState {
    pub fn new(n: usize, t: trace::Tracer) -> Self {
        Self {
            stack: partition_stack::PartitionStack::new(n),
            rbase_stack: Option::None,
            tracer: t,
            digraph_stack: DigraphStack::empty(n),
            digraph_stack_cells_refined: Backtracking::new(0),
        }
    }
}

impl State for PartitionState {
    fn partition(&self) -> &partition_stack::PartitionStack {
        &self.stack
    }

    fn has_rbase(&self) -> bool {
        self.rbase_stack.is_some()
    }
    fn snapshot_rbase(&mut self) {
        assert!(self.rbase_stack.is_none());
        self.rbase_stack = Some(self.stack.clone());
    }

    fn rbase_partition(&self) -> &partition_stack::PartitionStack {
        self.rbase_stack.as_ref().unwrap()
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
        // Need to refine whole graph
        *self.digraph_stack_cells_refined = 0;
    }

    fn add_graphs(&mut self, digraphs: &[Digraph]) {
        self.digraph_stack.add_graphs(digraphs);
        // Need to refine whole graph
        *self.digraph_stack_cells_refined = 0;
    }

    fn refine_graphs(&mut self) -> trace::Result<()> {
        while self.stack.cells() > *self.digraph_stack_cells_refined {
            let max_cells = self.stack.cells();
            info!(
                "Refining graph: {:?}",
                *self.digraph_stack_cells_refined..max_cells
            );
            self.stack.refine_partition_cells_by_graph(
                &mut self.tracer,
                self.digraph_stack.digraph(),
                *self.digraph_stack_cells_refined..max_cells,
            )?;
            *self.digraph_stack_cells_refined = max_cells;
        }
        Ok(())
    }
}

impl Backtrack for PartitionState {
    fn save_state(&mut self) {
        self.stack.save_state();
        self.tracer.save_state();
        self.digraph_stack.save_state();
        self.digraph_stack_cells_refined.save_state();
    }

    fn restore_state(&mut self) {
        self.stack.restore_state();
        self.tracer.restore_state();
        self.digraph_stack.restore_state();
        self.digraph_stack_cells_refined.restore_state();
    }
}
