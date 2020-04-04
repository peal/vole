use serde_derive::{Deserialize, Serialize};

use perm::Permutation;

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
pub struct Solutions {
    sols: Vec<Permutation>,
}

impl Solutions {
    pub fn add(&mut self, p: &Permutation) {
        self.sols.push(p.clone());
    }

    pub fn get(&mut self) -> &Vec<Permutation> {
        &self.sols
    }
}
