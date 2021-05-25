use crate::datastructures::sortedvec::SortedVec;

use super::{
    backtracking::Backtrack,
    domain_state::DomainState,
    refiners::{
        digraph::DigraphTransporter, refiner_store::RefinerStore, simple::SetTransporter, Refiner,
    },
    search::{simple_search, simple_single_search},
    solutions::Solutions,
    state::State,
    trace,
};

pub fn sub_search(state: &State) {
    let part_depth = state.domain.partition().state_depth();
    if state.domain.has_rbase() {
        let mut left_p = state.domain.rbase_partition().clone();
        let right_p = state.domain.partition();
        let depth = state.domain.partition().state_depth();
        assert!(left_p.state_depth() >= depth);
        while left_p.state_depth() > depth {
            left_p.restore_state();
        }

        let left_part = left_p
            .extended_as_list_set()
            .into_iter()
            .map(SortedVec::from_unsorted);
        let right_part = right_p
            .extended_as_list_set()
            .into_iter()
            .map(SortedVec::from_unsorted);

        assert_eq!(part_depth, state.domain.digraph_stack().state_depth());

        let left_graph = state.domain.rbase_digraph_stack().get_depth(part_depth);
        let right_graph = state.domain.digraph_stack().get_depth(part_depth);

        let mut refiners: Vec<Box<dyn Refiner>> = vec![Box::new(
            DigraphTransporter::new_transporter(left_graph.clone(), right_graph.clone()),
        )];

        for (left, right) in left_part.into_iter().zip(right_part) {
            refiners.push(Box::new(SetTransporter::new_transporter(left, right)));
        }

        let refiners = RefinerStore::new_from_refiners(refiners);
        let tracer = trace::Tracer::new();
        let domain = DomainState::new(state.domain.partition().extended_domain_size(), tracer);
        let mut solutions = Solutions::default();
        let mut state = State {
            domain,
            refiners,
            stats: Default::default(),
        };
        simple_single_search(&mut state, &mut solutions);
    } else {
        let right_p = state.domain.partition();
        let right_part = right_p
            .extended_as_list_set()
            .into_iter()
            .map(SortedVec::from_unsorted);

        let right_graph = state.domain.digraph_stack().get_depth(part_depth);

        let mut refiners: Vec<Box<dyn Refiner>> = vec![Box::new(
            DigraphTransporter::new_stabilizer(right_graph.clone()),
        )];

        for right in right_part.into_iter() {
            refiners.push(Box::new(SetTransporter::new_stabilizer(right)));
        }

        let refiners = RefinerStore::new_from_refiners(refiners);
        let tracer = trace::Tracer::new();
        let domain = DomainState::new(state.domain.partition().extended_domain_size(), tracer);
        let mut solutions = Solutions::default();
        let mut state = State {
            domain,
            refiners,
            stats: Default::default(),
        };
        simple_search(&mut state, &mut solutions);
    }
}
