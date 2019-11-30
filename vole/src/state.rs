use std::hash::Hash;

pub trait State {
    fn partition(&self) -> &partitionstack::PartitionStack;
    fn refine_partition_cell_by<F: Copy, T:Ord+Hash>(&mut self, i: usize, f: F) -> trace::Result<()>
        where F: Fn(&usize) -> T;
    fn refine_partition_by<F:Copy,T:Ord+Hash>(&mut self,  f: F) -> trace::Result<()>
        where F: Fn(&usize) -> T;
}

pub struct PartitionState<T: trace::Tracer> {
    stack: partitionstack::PartitionStack,
    tracer: T
}

impl<Tracer: trace::Tracer> PartitionState<Tracer> {
    fn new(n: usize, t: Tracer) -> PartitionState<Tracer> {
        PartitionState { stack: partitionstack::PartitionStack::new(n), tracer: t }
    }
}

impl<Tracer: trace::Tracer> State for PartitionState<Tracer> {
    fn partition(&self) -> &partitionstack::PartitionStack {
        &self.stack
    }

    fn refine_partition_cell_by<F: Copy, T:Ord+Hash>(&mut self, i: usize, f: F) -> trace::Result<()>
        where F: Fn(&usize) -> T
    { self.stack.refine_partition_cell_by(&mut self.tracer, i, f) }

    fn refine_partition_by<F:Copy,T:Ord+Hash>(&mut self,  f: F) -> trace::Result<()>
    where F: Fn(&usize) -> T
    { self.stack.refine_partition_by(&mut self.tracer, f) }
}