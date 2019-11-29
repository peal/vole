pub trait State {
    fn partition(&self) -> &partitionstack::PartitionStack;
    fn refine_partition_cell_by<F: Copy, T:Ord>(&mut self, i: usize, f: F) -> Result<(), ()>
        where F: Fn(&usize) -> T;
    fn refine_partition_by<F:Copy,T:Ord>(&mut self,  f: F) -> Result<(), ()>
        where F: Fn(&usize) -> T;
}

pub struct PartitionState {
    stack: partitionstack::PartitionStack
}

impl PartitionState {
    fn new(n: usize) -> PartitionState {
        PartitionState { stack: partitionstack::PartitionStack::new(n) }
    }
}

impl State for PartitionState {
    fn partition(&self) -> &partitionstack::PartitionStack {
        &self.stack
    }

    fn refine_partition_cell_by<F: Copy, T:Ord>(&mut self, i: usize, f: F) -> Result<(), ()>
        where F: Fn(&usize) -> T
    { self.stack.refine_partition_cell_by(i, f) }

    fn refine_partition_by<F:Copy,T:Ord>(&mut self,  f: F) -> Result<(), ()>
    where F: Fn(&usize) -> T
    { self.stack.refine_partition_by(f) }
}