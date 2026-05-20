use std::{hash::Hash, sync::Arc};

use tracing::info;

use crate::{
    datastructures::digraph::{Digraph, DigraphStack},
    vole::partition_stack,
};
use crate::{datastructures::hash::QuickHashable, vole::trace};

use std::fmt::Debug;

use crate::vole::backtracking::Backtrack;

use super::{backtracking::Backtracking, refiners::refiner_store::RefinerStore};

pub struct DomainState {
    stack: partition_stack::PartitionStack,
    rbase_stack: Option<partition_stack::PartitionStack>,
    tracer: trace::Tracer,
    digraph_stack: DigraphStack,
    rbase_digraph_stack: Option<DigraphStack>,
    digraph_stack_cells_refined: Backtracking<usize>,
    rbase_branch_vals: Vec<usize>,
    /// A refiner's proposal of the next point to branch on (0-indexed).
    /// The selector consults this in preference to its default policy.
    /// Reset to None at the start of each refinement cycle so the
    /// proposal only ever reflects refiners that fired during the most
    /// recent refinement. Backtracking-stacked so the proposal is
    /// per-search-node.
    proposed_branch_point: Backtracking<Option<usize>>,
    /// If set, the selector branches on points `< threshold` before any
    /// point `>= threshold`. The sub-search that finds `Aut(widget)` runs
    /// on the extended domain (base + auxiliary vertices) but sets this to
    /// the real base size `n`, so the rbase comes out as a real-point
    /// prefix (a base for the restricted group) followed by aux points.
    /// `None` (the outer search) leaves branching order untouched. Not
    /// backtracking-stacked: it is constant for the whole search.
    branch_first_threshold: Option<usize>,
}

impl DomainState {
    pub fn new(n: usize, t: trace::Tracer) -> Self {
        Self {
            stack: partition_stack::PartitionStack::new(n),
            rbase_stack: Option::None,
            tracer: t,
            digraph_stack: DigraphStack::empty(n),
            rbase_digraph_stack: Option::None,
            digraph_stack_cells_refined: Backtracking::new(0),
            rbase_branch_vals: vec![],
            proposed_branch_point: Backtracking::new(None),
            branch_first_threshold: None,
        }
    }
}

impl DomainState {
    pub fn partition(&self) -> &partition_stack::PartitionStack {
        &self.stack
    }

    pub fn tracer(&self) -> &trace::Tracer {
        &self.tracer
    }

    pub fn add_trace_event(&mut self, e: trace::TraceEvent) -> Result<(), trace::TraceFailure> {
        self.tracer.add(e)
    }

    pub fn has_rbase(&self) -> bool {
        self.rbase_stack.is_some()
    }

    pub fn push_rbase_branch_val(&mut self, i: usize) {
        self.rbase_branch_vals.push(i)
    }

    pub fn rbase_branch_vals(&self) -> &[usize] {
        &self.rbase_branch_vals
    }
    fn inject_known_solutions(&mut self) {
        //GapChatType::send_request(&("known_solutions"), )
    }

    pub fn snapshot_rbase(&mut self, refiners: &mut RefinerStore) {
        assert!(self.rbase_stack.is_none());
        self.rbase_stack = Some(self.stack.clone());
        self.rbase_digraph_stack = Some(self.digraph_stack.clone());
        self.inject_known_solutions();
        refiners.snapshot_rbase(self);
    }

    pub fn rbase_partition(&self) -> &Option<partition_stack::PartitionStack> {
        &self.rbase_stack
    }

    pub fn rbase_digraph_stack(&self) -> &DigraphStack {
        self.rbase_digraph_stack.as_ref().unwrap()
    }

    pub fn digraph_stack(&self) -> &DigraphStack {
        &self.digraph_stack
    }

    pub fn add_invariant_fact<T: Ord + Hash + Debug + QuickHashable>(&mut self, reason: T) -> trace::Result<()> {
        self.tracer.add(trace::TraceEvent::Fact {
            reason: reason.quick_hash().0,
        })
    }

    pub fn refine_partition_cell_by<F: Copy, T: Ord + Hash + Debug + QuickHashable>(
        &mut self,
        i: usize,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> T,
    {
        self.stack.refine_partition_cell_by(&mut self.tracer, i, f)
    }

    pub fn base_refine_partition_by<F: Copy, T: Ord + Hash + Debug + QuickHashable>(
        &mut self,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> T,
    {
        self.stack.base_refine_partition_by(&mut self.tracer, f)
    }

    pub fn extended_refine_partition_by<F: Copy, T: Ord + Hash + Debug + QuickHashable>(
        &mut self,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> T,
    {
        self.stack.extended_refine_partition_by(&mut self.tracer, f)
    }

    /// Extend partition with `extra` points (return label of new partition)
    pub fn extend_partition(&mut self, extra: usize) -> usize {
        self.stack.extend(extra)
    }

    pub fn add_arc_graph(&mut self, d: &Arc<Digraph>) {
        self.digraph_stack.add_arc_graph(d);
        // Need to refine whole graph
        *self.digraph_stack_cells_refined = 0;
    }

    pub fn add_graph(&mut self, d: &Digraph) {
        self.digraph_stack.add_graph(d);
        // Need to refine whole graph
        *self.digraph_stack_cells_refined = 0;
    }

    fn add_graphs(&mut self, digraphs: &[Digraph]) {
        self.digraph_stack.add_graphs(digraphs);
        // Need to refine whole graph
        *self.digraph_stack_cells_refined = 0;
    }

    /// A refiner may call this during refinement to nominate a point
    /// for the selector to branch on next. The selector chooses the
    /// cell containing this point if its size > 1; otherwise falls
    /// back to its default policy. `p` is a 0-indexed point.
    pub fn set_proposed_branch_point(&mut self, p: usize) {
        *self.proposed_branch_point = Some(p);
    }

    /// Clear any pending branch-point proposal. Called by the refiner
    /// store at the start of each refinement cycle so a proposal only
    /// ever reflects refiners that fired during that cycle.
    pub fn clear_proposed_branch_point(&mut self) {
        *self.proposed_branch_point = None;
    }

    pub fn proposed_branch_point(&self) -> Option<usize> {
        *self.proposed_branch_point
    }

    pub fn set_branch_first_threshold(&mut self, t: usize) {
        self.branch_first_threshold = Some(t);
    }

    pub fn branch_first_threshold(&self) -> Option<usize> {
        self.branch_first_threshold
    }

    pub fn refine_graphs(&mut self) -> trace::Result<()> {
        info!("Refining graph cells");
        self.stack.refine_partition_cells_by_graph(
            &mut self.tracer,
            self.digraph_stack.digraph(),
            *self.digraph_stack_cells_refined,
        )?;
        *self.digraph_stack_cells_refined = self.partition().extended_cells().len();
        Ok(())
    }
}

impl Backtrack for DomainState {
    fn save_state(&mut self) {
        self.stack.save_state();
        self.tracer.save_state();
        self.digraph_stack.save_state();
        self.digraph_stack_cells_refined.save_state();
        self.proposed_branch_point.save_state();
    }

    fn restore_state(&mut self) {
        self.stack.restore_state();
        self.tracer.restore_state();
        self.digraph_stack.restore_state();
        self.digraph_stack_cells_refined.restore_state();
        self.proposed_branch_point.restore_state();
    }

    fn state_depth(&self) -> usize {
        debug_assert_eq!(self.stack.state_depth(), self.tracer.state_depth());
        debug_assert_eq!(self.stack.state_depth(), self.digraph_stack.state_depth());
        debug_assert_eq!(self.stack.state_depth(), self.digraph_stack_cells_refined.state_depth());
        debug_assert_eq!(self.stack.state_depth(), self.proposed_branch_point.state_depth());
        self.stack.state_depth()
    }
}
