extern crate serde;
extern crate serde_derive;
extern crate serde_json;
use serde_derive::{Deserialize, Serialize};

use digraph::Digraph;

use crate::refiners::digraph::DigraphStabilizer;
use crate::refiners::simple::SetStabilizer;
use crate::refiners::simple::TupleStabilizer;
use crate::refiners::Refiner;
use crate::state::PartitionState;

use anyhow::Result;

use std::io::BufRead;

trait RefinerDescription {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>>;
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphStab {
    edges: Vec<Vec<usize>>,
}

impl RefinerDescription for DigraphStab {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>> {
        Box::new(DigraphStabilizer::new(Digraph::from_vec(
            self.edges.clone(),
        )))
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SetStab {
    points: Vec<usize>,
}

impl RefinerDescription for SetStab {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>> {
        Box::new(SetStabilizer::new(self.points.iter().cloned().collect()))
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct TupleStab {
    points: Vec<usize>,
}

impl RefinerDescription for TupleStab {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>> {
        Box::new(TupleStabilizer::new(self.points.clone()))
    }
}
#[derive(Debug, Deserialize, Serialize)]
pub enum Constraint {
    DigraphStab(DigraphStab),
    SetStab(SetStab),
    TupleStab(TupleStab),
}

impl RefinerDescription for Constraint {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>> {
        match self {
            Constraint::DigraphStab(c) => c.build_refiner(),
            Constraint::SetStab(c) => c.build_refiner(),
            Constraint::TupleStab(c) => c.build_refiner(),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    pub points: usize,
    pub findgens: bool,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Problem {
    pub config: Config,
    pub constraints: Vec<Constraint>,
    pub debug: bool,
}

pub fn build_constraints(constraints: &Vec<Constraint>) -> Vec<Box<dyn Refiner<PartitionState>>> {
    constraints.iter().map(|x| x.build_refiner()).collect()
}
pub fn read_problem<R: BufRead>(prob: &mut R) -> Result<Problem> {
    let mut line = String::new();
    let _ = prob.read_line(&mut line)?;
    let parsed: Problem = serde_json::from_str(&line)?;
    Ok(parsed)
}
