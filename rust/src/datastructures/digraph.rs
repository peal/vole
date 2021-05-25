//! Edge-coloured Graphs
//!
//! This crate implements edge-coloured graphs.

use serde::{Deserialize, Serialize};
use std::{collections::HashSet, num::Wrapping, slice, sync::Arc};

use crate::{
    perm::Permutation,
    vole::backtracking::{Backtrack, Backtracking},
};
use itertools::Itertools;
use tracing::trace;

use super::hash::{QHash, QuickHashable};

/// The neighbours of a vertex in a directed graph.
/// The keys are the neighbours, the image of the keys the "colour" of the edge
/// Directed graphs have edges in both directions, but with different colours.
pub type Neighbours = std::collections::BTreeMap<usize, Wrapping<QHash>>;
//pub type Neighbours = indexmap::map::IndexMap<usize, Wrapping<QHash>>;

/// A directed graph
#[derive(Clone, Debug, Eq, Deserialize, Serialize)]
pub struct Digraph {
    /// The neighbours of each vertex, stored as a list
    edges: Vec<Neighbours>,
}

impl std::hash::Hash for Digraph {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        for (i, row) in self.edges.iter().enumerate() {
            i.hash(state);
            for r in row {
                r.hash(state);
            }
        }
    }
}

impl PartialEq<Self> for Digraph {
    fn eq(&self, other: &Self) -> bool {
        // Check edges are sorted and unique
        assert!(self
            .edges
            .iter()
            .all(|e| e.keys().tuple_windows().all(|(a, b)| a < b)));
        self.edges == other.edges
    }
}

impl Ord for Digraph {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        // Check edges are sorted and unique
        assert!(self
            .edges
            .iter()
            .all(|e| e.keys().tuple_windows().all(|(a, b)| a < b)));
        assert!(self.edges.len() == other.edges.len());

        for (left, right) in self.edges.iter().zip(other.edges.iter()) {
            let c = left.iter().cmp(right.iter());
            if c != std::cmp::Ordering::Equal {
                return c;
            }
        }
        std::cmp::Ordering::Equal
    }
}

impl PartialOrd<Self> for Digraph {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Digraph {
    /// The empty digraph on n vertices
    pub fn empty(n: usize) -> Self {
        Self {
            edges: vec![Neighbours::new(); n],
        }
    }

    /// Make a digraph from a vector of vector of neighbours
    pub fn from_vec(in_edges: Vec<Vec<usize>>) -> Self {
        let mut edges: Vec<Neighbours> = vec![Neighbours::new(); in_edges.len()];

        let out_edge = 1usize.quick_hash();
        let in_edge = 2usize.quick_hash();

        for (i, item) in in_edges.iter().enumerate() {
            for &edge in item {
                *edges[i].entry(edge).or_insert(Wrapping(0)) += out_edge;
                *edges[edge].entry(i).or_insert(Wrapping(0)) += in_edge;
            }
        }

        /*for e in &mut edges {
            e.sort_keys();
        }*/

        Self { edges }
    }

    /// [Digraph::from_vec], where the vertices are 1-indexed.
    pub fn from_one_indexed_vec(mut in_edges: Vec<Vec<usize>>) -> Self {
        for line in &mut in_edges {
            for v in line {
                *v -= 1;
            }
        }
        Self::from_vec(in_edges)
    }

    /// Number of vertices
    pub fn vertices(&self) -> usize {
        self.edges.len()
    }

    /// Neighbours of vertex `i`
    pub fn neighbours(&self, i: usize) -> &Neighbours {
        &self.edges[i]
    }

    /// Merge a list of digraphs into this graph. This new graph
    /// will contain all edges both from the original graph, and
    /// from all elements of `digraphs`. It's automorphism group
    /// should be the intersection of the automorphism groups of
    /// itself, and the elements of digraphs, but it may be larger
    /// in some cases (due to hash collisions).
    /// The `in_depth` argument is used to "stack" calls to merge,
    /// so merging [a,b,c,d,e] at depth 0 will produce the same graph
    /// as first mergeing [a,b] at depth 0, the [c,d,e] at depth 2.
    /// whereas merging [a,b] at depth 0, then [c,d,e] at depth 0 will
    /// produce a different graph
    pub fn merge(&mut self, digraphs: &[Self], in_depth: usize) {
        let mut resort = HashSet::new();
        for (size, d) in digraphs.iter().enumerate() {
            let depth = in_depth + size;
            if d.edges.len() > self.edges.len() {
                self.edges.resize(d.edges.len(), Neighbours::new());
                for i in self.edges.len()..d.edges.len() {
                    resort.insert(i);
                }
            }

            for i in 0..d.edges.len() {
                for (&neighbour, &colour) in &d.edges[i] {
                    *self.edges[i].entry(neighbour).or_insert_with(|| {
                        resort.insert(i);
                        Wrapping(0)
                    }) += ((colour, depth)).quick_hash();
                }
            }
        }

        /* for i in resort.into_iter() {
            self.edges[i].sort_keys();
        }*/
    }

    /// Relabel the vertices of a graph, possibly introducing some new unused vertices
    /// in the process. `map` should be as long as `self.vertices()`.
    pub fn remap_vertices(&mut self, map: &[usize]) {
        assert!(map.len() == self.edges.len());
        let max_val = *map.iter().max().unwrap_or(&0);
        let mut new_edges: Vec<Neighbours> = vec![Neighbours::new(); max_val + 1];

        for (loc, e) in self.edges.iter().enumerate() {
            let image = map[loc];
            for (&vert, &label) in e {
                new_edges[image].insert(map[vert], label);
            }
        }

        self.edges = new_edges;
    }
}

/// Apply a Permutation to a Digraph
impl std::ops::BitXor<&Permutation> for &Digraph {
    type Output = Digraph;

    fn bitxor(self, perm: &Permutation) -> Self::Output {
        let mut edges: Vec<Neighbours> = vec![Neighbours::new(); self.edges.len()];
        for i in 0..self.edges.len() {
            let i_img = perm.apply(i);
            for (&target, &colour) in &self.edges[i] {
                edges[i_img].insert(perm.apply(target), colour);
            }
            // edges[i_img].sort_keys();
        }

        Digraph { edges }
    }
}

/// A backtrackable Digraph, which can be merged with other Digraphs
#[derive(Clone, Debug)]
pub struct DigraphStack {
    digraph: Backtracking<Arc<Digraph>>,
    depth: Backtracking<usize>,
}

impl DigraphStack {
    /// Create an initial empty digraph on `n` vertices
    pub fn empty(n: usize) -> Self {
        Self {
            digraph: Backtracking::new(Arc::new(Digraph::empty(n))),
            depth: Backtracking::new(0),
        }
    }

    /// Get current digraph
    pub fn digraph(&self) -> &Digraph {
        &**self.digraph
    }

    /// Merge in a digraph stored in an Arc
    pub fn add_arc_graph(&mut self, d: &Arc<Digraph>) {
        trace!("Adding digraph by arc");
        // TODO: Make this more efficient, when this is the first graph
        self.add_graph(d.as_ref());
        *self.depth += 1;
    }

    /// Merge in a digraph
    pub fn add_graph(&mut self, d: &Digraph) {
        trace!("Adding digraph");
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(slice::from_ref(d), *self.depth);
        *self.depth += 1;
    }

    /// Merge in a list of digraphs
    pub fn add_graphs(&mut self, digraphs: &[Digraph]) {
        trace!("Adding {} digraphs", digraphs.len());
        let digraph: &mut Digraph = Arc::make_mut(&mut (*self.digraph));
        digraph.merge(digraphs, *self.depth);
        *self.depth += digraphs.len();
    }

    /// Get digraph at depth `d`
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

    fn state_depth(&self) -> usize {
        debug_assert_eq!(self.digraph.state_depth(), self.depth.state_depth());
        self.digraph.state_depth()
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
