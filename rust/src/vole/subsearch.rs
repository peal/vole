use crate::vole::trace::TraceEvent::FullGraph;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use tracing::info;

/// Counts how many sub-searches are currently active on this thread.
/// Incremented by `SubSearchGuard::enter()` (held by `sub_full_refine`)
/// and decremented on drop. Read by `GapChatType::send_request`, which
/// panics if it fires while non-zero — see the rationale on that
/// function: the GAP-side session has no protocol for sub-search-
/// scoped callbacks, so any callback from within a sub-search is a
/// bug.
pub static IN_SUB_SEARCH: AtomicUsize = AtomicUsize::new(0);

/// RAII guard for the IN_SUB_SEARCH counter.
pub struct SubSearchGuard;

impl SubSearchGuard {
    pub fn enter() -> Self {
        IN_SUB_SEARCH.fetch_add(1, Ordering::SeqCst);
        Self
    }
}

impl Drop for SubSearchGuard {
    fn drop(&mut self) {
        IN_SUB_SEARCH.fetch_sub(1, Ordering::SeqCst);
    }
}

use crate::datastructures::{digraph::Digraph, hash::do_hash, sortedvec::SortedVec};

use super::{
    backtracking::Backtrack,
    domain_state::DomainState,
    refiners::{digraph::DigraphTransporter, refiner_store::RefinerStore, simple::SetTransporter, Refiner},
    search::{simple_coset_search, simple_group_search, SearchConfig},
    solutions::Solutions,
    state::State,
    trace::{self, TraceFailure},
};

fn sub_single_search(state: &mut State, search_config: &SearchConfig) -> Solutions {
    state.save_state();
    let part_depth = state.domain.partition().state_depth() - 1;
    assert!(state.domain.has_rbase());
    let mut left_p = state.domain.rbase_partition().as_ref().unwrap().clone();
    let right_p = state.domain.partition();
    let depth = state.domain.partition().state_depth();
    assert!(left_p.state_depth() >= depth);
    while left_p.state_depth() > depth {
        left_p.restore_state();
    }

    let left_part = left_p.extended_as_list_set().into_iter().map(SortedVec::from_unsorted);
    let right_part = right_p.extended_as_list_set().into_iter().map(SortedVec::from_unsorted);

    assert_eq!(part_depth, state.domain.digraph_stack().state_depth());

    let left_graph = state.domain.rbase_digraph_stack().get_depth(part_depth);
    let right_graph = state.domain.digraph_stack().get_depth(part_depth);

    let mut refiners: Vec<Box<dyn Refiner>> = vec![Box::new(DigraphTransporter::new_transporter(
        left_graph.clone(),
        right_graph.clone(),
    ))];

    for (left, right) in left_part.into_iter().zip(right_part) {
        refiners.push(Box::new(SetTransporter::new_transporter(left, right)));
    }

    let refiners = RefinerStore::new_from_refiners(refiners);
    let tracer = trace::Tracer::new();
    let dsize = state.domain.partition().extended_domain_size();
    let domain = DomainState::new(dsize, tracer);
    let mut solutions = Solutions::new(dsize);
    let mut new_state = State {
        domain,
        refiners,
        stats: Default::default(),
    };
    simple_coset_search(&mut new_state, &mut solutions, search_config);
    state.restore_state();
    solutions
}

pub fn sub_simple_search(state: &mut State, search_config: &SearchConfig) -> (Solutions, Arc<Digraph>) {
    // Save / restore the OUTER state OUTSIDE the SubSearchGuard. The
    // outer refiners are GAP refiners whose save_state/restore_state
    // round-trips to GAP — that's allowed (the GAP-side state machine
    // is the outer search) and must NOT panic the guard. The guard is
    // only active for the actual sub-search work between save and
    // restore, during which any GAP callback would be reading from
    // the wrong context.
    state.save_state();
    let part_depth = state.domain.partition().state_depth() - 1;

    let right_p = state.domain.partition();
    let right_part = right_p.extended_as_list_set().into_iter().map(SortedVec::from_unsorted);

    let right_graph = state.domain.digraph_stack().get_depth(part_depth).clone();

    let mut refiners: Vec<Box<dyn Refiner>> = vec![Box::new(DigraphTransporter::new_stabilizer(right_graph.clone()))];

    for right in right_part {
        refiners.push(Box::new(SetTransporter::new_stabilizer(right)));
    }

    let refiners = RefinerStore::new_from_refiners(refiners);
    let tracer = trace::Tracer::new();
    let dsize = state.domain.partition().extended_domain_size();
    let domain = DomainState::new(dsize, tracer);
    let mut solutions = Solutions::new(dsize);
    let mut new_state = State {
        domain,
        refiners,
        stats: Default::default(),
    };
    {
        let _guard = SubSearchGuard::enter();
        simple_group_search(&mut new_state, &mut solutions, search_config);
    }
    state.restore_state();
    (solutions, right_graph)
}

pub fn sub_full_refine(state: &mut State, search_config: &SearchConfig) -> Result<(), TraceFailure> {
    info!(
        "Sub search with input domain {:?}",
        state.domain.partition().extended_as_list_set()
    );

    let mut new_search_config = (*search_config).clone();
    new_search_config.full_graph_refine = false;
    // The sub-search runs against a fresh State whose natural
    // canonical context is `Sym(sub_domain_size)` (we just want the
    // automorphism orbits of the digraph stack snapshot). That's
    // exactly the trivial case GAP's canonicalmin handler short-
    // circuits — and crucially, the sub-search must not call back
    // into GAP at all (see the in_sub_search guard in gap_chat.rs).
    // Force the local canonical-min path so check_canonical never
    // touches GapChatType.
    new_search_config.canonical_min_trivial = true;
    let (sols, digraph) = sub_simple_search(state, &new_search_config);
    info!("Sub Sols: {:?}", sols.get());
    let canonical = sols.get_canonical().as_ref().unwrap().perm.clone();
    let can_inv = canonical.inv();
    let orbits = sols.orbits();
    let v = orbits.to_vec_vec();
    info!("Sub dump {:?} {:?}", canonical, v);
    // We need to order the orbits in the context of the canonical image
    let mut v_can: Vec<Vec<usize>> = v
        .into_iter()
        .map(|o| o.into_iter().map(|x| canonical.apply(x)).collect())
        .collect();
    for v in &mut v_can {
        v.sort();
    }
    v_can.sort();

    info!("Sub canonical domains {:?}", v_can);

    // Now map it back
    let v_ord: Vec<Vec<usize>> = v_can
        .into_iter()
        .map(|o| o.into_iter().map(|x| can_inv.apply(x)).collect())
        .collect();

    info!("Sub mapped back {:?}", v_ord);
    let mut map = vec![0; state.domain.partition().extended_domain_size()];
    for (i, o) in v_ord.into_iter().enumerate() {
        for x in o {
            map[x] = i;
        }
    }

    info!("Sub Full graph refine: {:?}", map);
    state.domain.base_refine_partition_by(|&x| map[x])?;

    let graph_canonical = (&*digraph) ^ &canonical;
    state.domain.add_trace_event(FullGraph {
        hash: do_hash(graph_canonical),
    })?;

    Ok(())
}
