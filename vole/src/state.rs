use std::hash::Hash;

pub trait State {
    fn partition(&self) -> &partitionstack::PartitionStack;

    fn has_rbase(&self) -> bool;
    fn snapshot_rbase(&mut self);
    fn rbase_partition(&self) -> &partitionstack::PartitionStack;

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

    fn save_state(&self) -> usize;
    fn restore_state(&mut self, depth: usize);
}

pub struct PartitionState {
    stack: partitionstack::PartitionStack,
    rbasestack: Option<partitionstack::PartitionStack>,
    tracer: trace::Tracer,
}

impl PartitionState {
    pub fn new(n: usize, t: trace::Tracer) -> PartitionState {
        PartitionState {
            stack: partitionstack::PartitionStack::new(n),
            rbasestack: Option::None,
            tracer: t,
        }
    }
}

impl State for PartitionState {
    fn partition(&self) -> &partitionstack::PartitionStack {
        &self.stack
    }

    fn has_rbase(&self) -> bool {
        self.rbasestack.is_some()
    }
    fn snapshot_rbase(&mut self) {
        assert!(self.rbasestack.is_none());
        self.rbasestack = Some(self.stack.clone());
    }

    fn rbase_partition(&self) -> &partitionstack::PartitionStack {
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

    fn save_state(&self) -> usize {
        self.stack.cells()
    }

    fn restore_state(&mut self, depth: usize) {
        self.stack.unsplit_cells_to(depth)
    }
}
