//! Directed Graphs
//!
//! This crate implements directed graphs

pub trait Edge: Copy + Clone + Ord + Sized {
    fn colour(&self) -> usize;
    fn end(&self) -> usize;
    fn newend(&self, vertex: usize) -> Self;
}

impl Edge for usize {
    fn colour(&self) -> usize {
        0
    }
    fn end(&self) -> usize {
        *self
    }
    fn newend(&self, vertex: usize) -> Self {
        vertex
    }
}

/// Represents a digraph
/// 'outedges' represents the edges out from vertex i
/// 'inedges' representes the edges into vertex i
#[derive(Clone, Debug, PartialEq, Eq, Ord, PartialOrd)]
pub struct Digraph<E: Edge> {
    outedges: Vec<Vec<E>>,
    inedges: Vec<Vec<E>>,
}

impl<E: Edge> Digraph<E> {
    /// Get the empty digraph on n vertices
    pub fn empty(n: usize) -> Digraph<E> {
        Digraph {
            outedges: vec![vec![]; n],
            inedges: vec![vec![]; n],
        }
    }

    pub fn from_vec(mut outedges: Vec<Vec<E>>) -> Digraph<E> {
        let mut inedges = vec![vec![]; outedges.len()];

        for (i, item) in outedges.iter().enumerate() {
            for edge in item {
                inedges[edge.end()].push(edge.newend(i))
            }
        }

        for o in &mut outedges {
            o.sort();
        }

        for i in &mut inedges {
            i.sort();
        }

        Digraph { outedges, inedges }
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
