use serde::{Deserialize, Serialize};

use super::Permutation;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Location {
    depth: usize,
    perm: Permutation,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ShrierVector {
    base: usize,
    map: Vec<Option<Location>>,
}

pub struct StabChain {
    chain: Vec<ShrierVector>,
}

impl StabChain {
    //pub fn build_chain(Vec<Permutation>)
}
