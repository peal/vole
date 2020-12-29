//! Directed Graphs
//!
//! This crate implements directed graphs

use crate::perm::Permutation;

pub trait Edge: Copy + Clone + Ord + Sized + std::fmt::Debug {
    fn colour(&self) -> usize;
    fn end(&self) -> usize;
    fn replace_end(&self, i: usize) -> Self;
    fn apply(&self, p: &Permutation) -> Self;
}

impl Edge for usize {
    fn colour(&self) -> usize {
        0
    }
    fn end(&self) -> usize {
        *self
    }

    fn replace_end(&self, i: usize) -> Self {
        i
    }

    fn apply(&self, p: &Permutation) -> Self {
        p.apply(*self)
    }
}

/// Represents a digraph
/// 'out_edges' represents the edges out from vertex i
/// 'in_edges' represents the edges into vertex i
#[derive(Clone, Debug, PartialEq, Eq, Ord, PartialOrd)]
pub struct DigraphBase<E: Edge> {
    out_edges: Vec<Vec<E>>,
    in_edges: Vec<Vec<E>>,
}

impl<E: Edge> DigraphBase<E> {
    /// Get the empty digraph on n vertices
    pub fn empty(n: usize) -> DigraphBase<E> {
        DigraphBase {
            out_edges: vec![vec![]; n],
            in_edges: vec![vec![]; n],
        }
    }

    pub fn from_vec(mut out_edges: Vec<Vec<E>>) -> DigraphBase<E> {
        let mut in_edges = vec![vec![]; out_edges.len()];

        for (i, item) in out_edges.iter().enumerate() {
            for edge in item {
                in_edges[edge.end()].push(edge.replace_end(i))
            }
        }

        for o in &mut out_edges {
            o.sort();
        }

        for i in &mut in_edges {
            i.sort();
        }

        DigraphBase { out_edges, in_edges }
    }

    pub fn vertices(&self) -> usize {
        self.out_edges.len()
    }

    pub fn out_edges<'a>(&'a self, i: usize) -> &'a Vec<E> {
        &self.out_edges[i]
    }

    pub fn in_edges<'a>(&'a self, i: usize) -> &'a Vec<E> {
        &self.in_edges[i]
    }
}

impl<E: Edge> std::ops::BitXor<&Permutation> for &DigraphBase<E> {
    type Output = DigraphBase<E>;

    fn bitxor(self, perm: &Permutation) -> Self::Output {
        let mut out_edges: Vec<Vec<E>> = vec![vec![]; self.out_edges.len()];
        for i in 0..self.out_edges.len() {
            let i_img = perm.apply(i);
            for edge in &self.out_edges[i] {
                out_edges[i_img].push(edge.apply(perm));
            }
        }
        DigraphBase::from_vec(out_edges)
    }
}

pub type Digraph = DigraphBase<usize>;

#[cfg(test)]
mod tests {
    use super::Digraph;
    use crate::perm::Permutation;
    #[test]
    fn id_perm() {
        let d = Digraph::empty(3);
        assert_eq!(d.vertices(), 3);
        for i in 0..3 {
            assert_eq!(d.in_edges(i), &Vec::<usize>::new());
            assert_eq!(d.out_edges(i), &Vec::<usize>::new());
        }
        assert_eq!(d, d);
        let e = Digraph::empty(4);
        assert!(d != e);
        assert!(d < e);
        assert!(e >= d);
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
        assert!(d != f);
        assert_eq!(d, g);
    }
}
