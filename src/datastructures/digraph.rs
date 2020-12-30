//! Edge-coloured Graphs
//!
//! This crate implements edge-coloured graphs.


use indexmap::map::IndexMap;
use itertools::Itertools;
use crate::perm::Permutation;

use super::hash::do_hash;


type Neighbours = IndexMap<usize,usize>;
#[derive(Clone, Debug, Eq)]
pub struct Digraph {
    edges: Vec<Neighbours>
}

impl PartialEq<Digraph> for Digraph {
    fn eq(&self, other: &Digraph) -> bool {
        // Check edges are sorted and unique
        assert!(self.edges.iter().all(|e| e.keys().tuple_windows().all(|(a,b)| a < b)));
        self.edges == other.edges
    }
}

impl PartialOrd<Digraph> for Digraph {
    fn partial_cmp(&self, other: &Digraph) -> Option<std::cmp::Ordering> {
        // Check edges are sorted and unique
        assert!(self.edges.iter().all(|e| e.keys().tuple_windows().all(|(a,b)| a < b)));
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
    pub fn empty(n: usize) -> Digraph {
        Digraph {
            edges: vec![Neighbours::new(); n],
        }
    }

    pub fn from_vec(in_edges: Vec<Vec<usize>>) -> Digraph {
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

        Digraph{ edges }
    }

    pub fn vertices(&self) -> usize {
        self.edges.len()
    }

    pub fn neighbours<'a>(&'a self, i: usize) -> &'a Neighbours {
        &self.edges[i]
    }

    pub fn merge(&mut self, d: &Digraph, depth: usize) {
        if d.edges.len() > self.edges.len() {
            self.edges.resize(d.edges.len(), Neighbours::new());
        }

        for i in 0..d.edges.len() {
            for (&neighbour, &colour) in &d.edges[i] {
                *self.edges[i].entry(neighbour).or_insert(0) += do_hash((colour, depth));
            }
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

        Digraph{edges}
    }
}

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
        let e = (&d) ^ (&p);
        let f = (&d) ^ (&c2);
        let g = (&f) ^ (&c2);
        assert_eq!(d, e);
        assert!(d <= e);
        assert!(!(d < e));
        assert!(d != f);
        assert!(d < f);
        assert!(g < f);
        assert_eq!(d, g);
    }

    #[test]
    fn more_graph() {
        let d = Digraph::from_vec(vec![vec![1,2], vec![], vec![],vec![]]);
        let p = Permutation::from_vec(vec![1, 2, 0]);
        let c2 = Permutation::from_vec(vec![1, 0]);
        let e = (&d) ^ (&p);
        let f = (&d) ^ (&c2);
        let g = (&f) ^ (&c2);
        assert!(d < e);
        assert!(d < f);
        assert_eq!(d, g);
    }
}
