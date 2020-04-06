//! Directed Graphs
//!
//! This crate implements directed graphs

use perm::Permutation;

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
        (*self) ^ p
    }
}

/// Represents a digraph
/// 'outedges' represents the edges out from vertex i
/// 'inedges' representes the edges into vertex i
#[derive(Clone, Debug, PartialEq, Eq, Ord, PartialOrd)]
pub struct DigraphBase<E: Edge> {
    outedges: Vec<Vec<E>>,
    inedges: Vec<Vec<E>>,
}

impl<E: Edge> DigraphBase<E> {
    /// Get the empty digraph on n vertices
    pub fn empty(n: usize) -> DigraphBase<E> {
        DigraphBase {
            outedges: vec![vec![]; n],
            inedges: vec![vec![]; n],
        }
    }

    pub fn from_vec(mut outedges: Vec<Vec<E>>) -> DigraphBase<E> {
        let mut inedges = vec![vec![]; outedges.len()];

        for (i, item) in outedges.iter().enumerate() {
            for edge in item {
                inedges[edge.end()].push(edge.replace_end(i))
            }
        }

        for o in &mut outedges {
            o.sort();
        }

        for i in &mut inedges {
            i.sort();
        }

        DigraphBase { outedges, inedges }
    }

    pub fn vertices(&self) -> usize {
        self.outedges.len()
    }

    pub fn outedges<'a>(&'a self, i: usize) -> &'a Vec<E> {
        &self.outedges[i]
    }

    pub fn inedges<'a>(&'a self, i: usize) -> &'a Vec<E> {
        &self.inedges[i]
    }
}

impl<E: Edge> std::ops::BitXor<&Permutation> for &DigraphBase<E> {
    type Output = DigraphBase<E>;

    fn bitxor(self, perm: &Permutation) -> Self::Output {
        let mut outedges: Vec<Vec<E>> = vec![vec![]; self.outedges.len()];
        for i in 0..self.outedges.len() {
            let i_img = i ^ perm;
            for edge in &self.outedges[i] {
                outedges[i_img].push(edge.apply(&perm));
            }
        }
        let out = DigraphBase::from_vec(outedges);
        out
    }
}

pub type Digraph = DigraphBase<usize>;

#[cfg(test)]
mod tests {
    use crate::Digraph;
    use crate::Permutation;
    #[test]
    fn id_perm() {
        let d = Digraph::empty(3);
        assert_eq!(d.vertices(), 3);
        for i in 0..3 {
            assert_eq!(d.inedges(i), &Vec::<usize>::new());
            assert_eq!(d.outedges(i), &Vec::<usize>::new());
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
