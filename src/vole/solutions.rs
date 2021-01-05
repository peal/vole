use serde::{Deserialize, Serialize};
use tracing::trace;

use crate::perm::Permutation;

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
pub struct Solutions {
    sols: Vec<Permutation>,
    canonical: Option<Permutation>,
    nodes: u64,
    tracefails: u64,
    solsfails: u64,
}

impl Solutions {
    pub fn add(&mut self, p: &Permutation) {
        self.sols.push(p.clone());
    }

    pub fn get(&mut self) -> &Vec<Permutation> {
        &self.sols
    }

    pub fn write_one_indexed<W: std::io::Write>(&self, out: &mut W) -> anyhow::Result<()> {
        trace!("Ouputting {} solutions", self.sols.len());
        write!(out, "{{ \"sols\": ")?;
        let solsone: Vec<Vec<usize>> = self
            .sols
            .iter()
            .map(|s| s.as_vec().iter().map(|x| x + 1).collect())
            .collect();
        write!(out, "{:?}", solsone)?;
        write!(out, "}}")?;
        out.flush()?;
        Ok(())
    }
}
