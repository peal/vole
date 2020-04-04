extern crate serde;
extern crate serde_derive;
extern crate serde_json;
use serde_derive::{Deserialize, Serialize};

use crate::refiners::Refiner;
use crate::state::PartitionState;

use anyhow::Result;

use std::io::BufRead;

trait BuildRefiner {
    fn refiner(&self) -> Box<dyn Refiner<PartitionState>>;
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphStab {
    edges: Vec<Vec<u64>>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SetStab {
    points: Vec<u64>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct TupleStab {
    points: Vec<u64>,
}

#[derive(Debug, Deserialize, Serialize)]
pub enum Constraint {
    DigraphStab(DigraphStab),
    SetStab(SetStab),
    TupleStab(TupleStab),
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    points: u64,
    findgens: bool,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Problem {
    config: Config,
    constraints: Vec<Constraint>,
    debug: bool,
}

pub fn read_problem<R: BufRead>(prob: &mut R) -> Result<Problem> {
    let parsed: Problem = serde_json::from_reader(prob)?;
    Ok(parsed)
}
