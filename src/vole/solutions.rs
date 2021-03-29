use std::any::Any;

use crate::perm::Permutation;
use disjoint_sets::UnionFind;

#[derive(Debug)]
pub struct Canonical {
    pub perm: Permutation,
    pub images: Vec<Box<dyn Any>>,
}

#[derive(Debug, Default)]
pub struct Solutions {
    sols: Vec<Permutation>,
    orbits: UnionFind<usize>,
    canonical: Option<Canonical>,
    nodes: u64,
    tracefails: u64,
    solsfails: u64,
}

impl Solutions {
    pub fn add_solution(&mut self, p: &Permutation) {
        self.sols.push(p.clone());
        let max_p = p.lmp().unwrap_or(1);
        while max_p >= self.orbits.len() {
            self.orbits.alloc();
        }
        for i in 0..max_p {
            self.orbits.union(i, p.apply(i));
        }
    }

    pub fn min_in_orbit(&mut self, i: usize) -> bool {
        while i >= self.orbits.len() {
            self.orbits.alloc();
        }
        self.orbits.find(i) == i
    }

    pub fn get(&self) -> &Vec<Permutation> {
        &self.sols
    }

    pub fn get_canonical(&self) -> &Option<Canonical> {
        &self.canonical
    }

    pub fn set_canonical(&mut self, c: Option<Canonical>) {
        self.canonical = c
    }
}
