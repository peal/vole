extern crate serde;
extern crate serde_json;

extern crate serde_derive;
use serde_derive::{Deserialize, Serialize};

use anyhow::Result;

#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphStab {
    edges: Vec<Vec<u64>>
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SetStab {
    points: Vec<u64>
}


#[derive(Debug, Deserialize, Serialize)]
pub struct TupleStab {
    points: Vec<u64>
}

#[derive(Debug, Deserialize, Serialize)]
pub enum Constraint {
    DigraphStab(DigraphStab),
    SetStab(SetStab),
    TupleStab(TupleStab)
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    points: u64,
    findgens: bool
}


#[derive(Debug, Deserialize, Serialize)]
pub struct Problem {
    config: Config,
    constraints: Vec<Constraint>,
    debug: bool
}

pub fn read_problem(prob: &str) -> Result<Problem> {
    let parsed: Problem = serde_json::from_str(prob)?;
    Ok(parsed)
}