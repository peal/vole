pub trait State {
    fn partition(&self) -> &partitionstack::PartitionStack;
    // fn refine_partition(&self, i: usize, f: Fn) -> Result<(),()>;
    fn refine_partition_cell<F, T>(&self, i: usize, f: F) -> Result<(), ()>
    where
        F: Fn(usize) -> T;
    fn refine_partition<F, T>(&self, f: F) -> Result<(), ()>
    where
        F: Fn(usize) -> T;
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

    fn refine_par
}