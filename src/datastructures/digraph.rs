//! Edge-coloured Graphs
//!
//! This crate implements edge-coloured graphs.

use serde::{Deserialize, Serialize};
use std::{num::Wrapping, slice, sync::Arc};

use crate::{
    perm::Permutation,
    vole::backtracking::{Backtrack, Backtracking},
};
use indexmap::map::IndexMap;
use itertools::Itertools;
use tracing::trace;

use super::hash::do_hash;

pub type Neighbours = IndexMap<usize, Wrapping<usize>>;
#[derive(Clone, Debug, Eq, Deserialize, Serialize)]
pub struct Digraph {
    edges: Vec<Neighbours>,
}

impl PartialEq<Digraph> for Digraph {
    fn eq(&self, other: &Self) -> bool {
        // Check edges are sorted and unique
        assert!(self
            .edges
            .iter()
            .all(|e| e.keys().tuple_windows().all(|(a, b)| a < b)));
        self.edges == other.edges
    }
}

impl PartialOrd<Digraph> for Digraph {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        // Check edges are sorted and unique
        assert!(self
            .edges
            .iter()
            .all(|e| e.keys().tuple_windows().all(|(a, b)| a < b)));
        assert!(self.edges.len() == other.edges.len());

        for (left, right) in self.edges.iter().zip(other.edges.iter()) {
            let c = left.iter().cmp(right.iter());
            if c != std::cmp::Ordering::Equal {
                return Some(c);
            }
        }
        Some(std::cmp::Ordering::Equal)
    }
}

impl Digraph {
    /// Get the empty digraph on n vertices
    pub fn empty(n: usize) -> Self {
        Self {
            edges: vec![Neighbours::new(); n],
        }
    }

    pub fn from_vec(in_edges: Vec<Vec<usize>>) -> Self {
        let mut edges: Vec<Neighbours> = vec![Neighbours::new(); in_edges.len()];

        for (i, item) in in_edges.iter().enumerate() {
            for &edge in item {
                *edges[i].entry(edge).or_insert(Wrapping(0)) += Wrapping(1);
                *edges[edge].entry(i).or_insert(Wrapping(0)) += Wrapping(2);
            }
        }

        for e in &mut edges {
            e.sort_keys();
        }

        Self { edges }
    }

    pub fn vertices(&self) -> usize {
        self.edges.len()
    }

    pub fn neighbours(&self, i: usize) -> &Neighbours {
        &self.edges[i]
    }

    pub fn merge(&mut self, digraphs: &[Self], in_depth: usize) {
        for (size, d) in digraphs.iter().enumerate() {
            let depth = in_depth + size;
            if d.edges.len() > self.edges.len() {
                self.edges.resize(d.edges.len(), Neighbours::new());
            }

            for i in 0..d.edges.len() {
                for (&neighbour, &colour) in &d.edges[i] {
                    *self.edges[i].entry(neighbour).or_insert(Wrapping(0)) +=
                        do_hash((colour, depth));
                }
            }
        }

        for i in 0..self.edges.len() {
            self.edges[i].sort_keys();
        }
    }

    pub fn remap_vertices(&mut self, map: &Vec<usize>) {
        assert!(map.len() == self.edges.len());
        let max_val = *map.iter().max().unwrap_or(&0);
        let mut new_edges: Vec<Neighbours> = vec![Neighbours::new(); max_val];

        for (loc, e) in self.edges.iter().enumerate() {
            let image = map[loc];
            for (&vert, &label) in e {
                new_edges[image].insert(map[vert], label);
            }
        }

        self.edges = new_edges;
    }
}

impl std::ops::BitXor<&Permutation> for &Digraph {
    type Output = Digraph;

    fn bitxor(self, perm: &Permutation) -> Self::Output {
        let mut edges: Vec<Neighbours> = vec![Neighbours::new(); self.edges.len()];
        for i in 0..self.edges.len() {
            let i_img = perm.apply(i);
            for (&target, &colour) in &self.edges[i] {
                edges[i_img].insert(perm.apply(target), colour);
            }
            edges[i_img].sort_keys();
        }

        Digraph { edges }
    }
}

#[derive(Clone, Debug)]
pub struct DigraphStack {
    digraph: Backtracking<Arc<Digraph>>,
    depth: Backtracking<usize>,
}

impl DigraphStack {
    pub fn empty(n: usize) -> Self {
        Self {
            digraph: Backtracking::new(Arc::new(Digraph::empty(n))),
            depth: Backtracking::new(0),
        }
    }

    pub fn digraph(&self) -> &Digraph {
        &**self.digraph
    }

    pub fn add_arc_graph(&mut self, d: &Arc<Digraph>) {
        // TODO: Make this more efficient, when this is the first graph
        self.add_graph(d.as_ref())
    }

    pub fn add_graph(&mut self, d: &Digraph) {
        trace!("Adding digraph");
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(slice::from_ref(d), *self.depth);
        *self.depth += 1;
    }

    pub fn add_graphs(&mut self, digraphs: &[Digraph]) {
        trace!("Adding {} digraphs", digraphs.len());
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(digraphs, *self.depth);
        *self.depth += digraphs.len();
    }

    pub fn saved_depths(&self) -> usize {
        self.digraph.saved_depths()
    }

    pub fn get_depth(&self, d: usize) -> &Arc<Digraph> {
        self.digraph.get_depth(d)
    }
}

impl Backtrack for DigraphStack {
    fn save_state(&mut self) {
        self.digraph.save_state();
        self.depth.save_state();
    }

    fn restore_state(&mut self) {
        self.digraph.restore_state();
        self.depth.restore_state();
    }
}

#[allow(clippy::eq_op, clippy::neg_cmp_op_on_partial_ord)]
#[cfg(test)]
mod tests {
    use super::{Digraph, Neighbours};
    use crate::perm::Permutation;
    #[test]
    fn id_perm() {
        let d = Digraph::empty(3);
        assert_eq!(d.vertices(), 3);
        for i in 0..d.vertices() {
            let empty = Neighbours::new();
            assert_eq!(*d.neighbours(i), empty);
            assert_eq!(*d.neighbours(i), empty);
        }
        assert_eq!(d, d);
        assert!(!(d < d));
        assert!(d <= d);
    }

    #[test]
    fn empty_perm_graph() {
        let d = Digraph::empty(3);
        let p = Permutation::from_vec(vec![1, 0]);
        let e = (&d) ^ (&p);
        assert_eq!(d, e);
    }

    #[test]
    fn cycle_perm_graph() {
        let d = Digraph::from_vec(vec![vec![1], vec![2], vec![0]]);
        let p = Permutation::from_vec(vec![1, 2, 0]);
        let c2 = Permutation::from_vec(vec![1, 0]);
        let de = (&d) ^ (&p);
        let df = (&d) ^ (&c2);
        let dg = (&df) ^ (&c2);
        assert_eq!(d, de);
        assert!(d <= de);
        assert!(!(d < de));
        assert!(d != df);
        assert!(d < df);
        assert!(dg < df);
        assert_eq!(d, dg);
    }

    #[test]
    fn more_graph() {
        let d = Digraph::from_vec(vec![vec![1, 2], vec![], vec![], vec![]]);
        let p = Permutation::from_vec(vec![1, 2, 0]);
        let c2 = Permutation::from_vec(vec![1, 0]);
        let de = (&d) ^ (&p);
        let df = (&d) ^ (&c2);
        let dg = (&df) ^ (&c2);
        assert!(d < de);
        assert!(d < df);
        assert_eq!(d, dg);
    }
}
