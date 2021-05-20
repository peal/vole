use serde::{Deserialize, Serialize};
#[derive(Default, Debug, Clone, Deserialize, Serialize)]
pub struct Stats {
    /// Total number of nodes in the search tree
    pub search_nodes: usize,
    /// Number of leaves where the stabilizer trace has not been violated, which were not solutions
    pub bad_iso: usize,
    /// Number of leaves where the stabilizer trace has not been violated, which were solutions
    pub good_iso: usize,
    /// Number of leaves where the canonical trace has not been violated, which were 'bigger'
    pub bad_canonical: usize,
    /// Number of leaves where the canonical trace has not been violated, which were 'smaller'
    pub improve_canonical: usize,
    /// Number of leaves where the canonical trace has not been violated, which were 'equal'
    pub equal_canonical: usize,
    /// Total number of times refiners have been called
    pub refiner_calls: usize,
    /// Branching points of the rbase
    rbase_branch_vals: Vec<usize>,
}

impl Stats {
    pub fn push_rbase_branch_val(&mut self, p: usize) {
        self.rbase_branch_vals.push(p + 1);
    }
}
