use crate::datastructures::unionfind::UnionFind;
use std::any::Any;

use crate::perm::Permutation;

#[derive(Debug)]
pub struct Canonical {
    pub trace_version: usize,
    pub perm: Permutation,
    pub images: Vec<Box<dyn Any>>,
}

#[derive(Debug)]
pub struct Solutions {
    first_sol_inv: Option<Permutation>,
    sols: Vec<Permutation>,
    orbits: UnionFind,
    canonical: Option<Canonical>,
    nodes: u64,
    tracefails: u64,
    solsfails: u64,
}

impl Solutions {
    pub fn new(max: usize) -> Self {
        Self {
            first_sol_inv: None,
            sols: vec![],
            orbits: UnionFind::new(max),
            canonical: None,
            nodes: 0,
            tracefails: 0,
            solsfails: 0,
        }
    }

    pub fn add_solution(&mut self, p: &Permutation) {
        if self.first_sol_inv.is_none() {
            self.first_sol_inv = Some(p.inv());
        }

        let _p_coset = p.multiply(self.first_sol_inv.as_ref().unwrap());

        self.sols.push(p.clone());

        self.orbits.union_permutation(p);
    }

    pub fn min_in_orbit(&mut self, i: usize) -> bool {
        match self.first_sol_inv.as_ref() {
            Some(_) => {
                let i = self.first_sol_inv.as_ref().unwrap().apply(i);
                self.orbits.expand_to(i);
                self.orbits.find(i) == i
            }
            None => true,
        }
    }

    pub fn orbits(&self) -> &UnionFind {
        &self.orbits
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
