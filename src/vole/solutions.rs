use disjoint_sets::UnionFind;
use serde::{Deserialize, Serialize};
use tracing::trace;

use crate::perm::Permutation;

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
pub struct Solutions {
    sols: Vec<Permutation>,
    orbits: UnionFind<usize>,
    //    canonical: Option<Permutation>,
    nodes: u64,
    tracefails: u64,
    solsfails: u64,
}

#[derive(Debug, Deserialize, Serialize)]
struct Results {
    sols: Vec<Vec<usize>>,
}

impl Solutions {
    pub fn add(&mut self, p: &Permutation) {
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

    pub fn get(&mut self) -> &Vec<Permutation> {
        &self.sols
    }

    pub fn write_one_indexed<W: std::io::Write>(&self, mut out: &mut W) -> anyhow::Result<()> {
        trace!("Ouputting {} solutions", self.sols.len());

        let solsone: Vec<Vec<usize>> = self
            .sols
            .iter()
            .map(|s| s.as_vec().iter().map(|x| x + 1).collect())
            .collect();

        serde_json::to_writer(&mut out, &("end", Results { sols: solsone }))?;
        out.flush()?;
        Ok(())
    }
}
