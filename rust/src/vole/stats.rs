use serde::{Deserialize, Serialize};
#[derive(Default, Debug, Clone, Deserialize, Serialize)]
pub struct Stats {
    pub rbase_nodes: usize,
    pub search_nodes: usize,
    pub bad_iso: usize,
    pub good_iso: usize,
    pub bad_canonical: usize,
    pub improve_canonical: usize,
    pub equal_canonical: usize,
    pub refiner_calls: usize,
    rbase_branch_vals: Vec<usize>,
}

impl Stats {
    pub fn push_rbase_branch_val(&mut self, p: usize) {
        self.rbase_branch_vals.push(p + 1);
    }
}
