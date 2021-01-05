//! Edge-coloured Graphs
//!
//! This crate implements edge-coloured graphs.

use std::{slice, sync::Arc};

use crate::{
    perm::Permutation,
    vole::backtracking::{Backtrack, Backtracking},
};
use indexmap::map::IndexMap;
use itertools::Itertools;

use super::hash::do_hash;

type Neighbours = IndexMap<usize, usize>;
#[derive(Clone, Debug, Eq)]
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
                *edges[i].entry(edge).or_insert(0) += 1;
                *edges[edge].entry(i).or_insert(0) += 2;
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

    pub fn merge(&mut self, dgraphs: &[Self], in_depth: usize) {
        for (size, d) in dgraphs.iter().enumerate() {
            let depth = in_depth + size;
            if d.edges.len() > self.edges.len() {
                self.edges.resize(d.edges.len(), Neighbours::new());
            }

            for i in 0..d.edges.len() {
                for (&neighbour, &colour) in &d.edges[i] {
                    *self.edges[i].entry(neighbour).or_insert(0) += do_hash((colour, depth));
                }
            }
        }

        for i in 0..self.edges.len() {
            self.edges[i].sort_keys();
        }
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

    pub fn add_graph(&mut self, d: &Digraph) {
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(slice::from_ref(d), *self.depth);
        *self.depth += 1;
    }

    pub fn add_graphs(&mut self, dgraphs: &[Digraph]) {
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(dgraphs, *self.depth);
        *self.depth += dgraphs.len();
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
            let ehash = Neighbours::new();
            assert_eq!(*d.neighbours(i), ehash);
            assert_eq!(*d.neighbours(i), ehash);
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
