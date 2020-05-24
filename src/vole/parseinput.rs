use serde::{Deserialize, Serialize};

use crate::digraph::Digraph;

use super::refiners::digraph::DigraphStabilizer;
use super::refiners::simple::SetStabilizer;
use super::refiners::simple::TupleStabilizer;
use super::refiners::Refiner;
use super::state::PartitionState;

use anyhow::Result;

use std::io::BufRead;

trait RefinerDescription {
    fn build_refiner(&self) -> Box<dyn Refiner<PartitionState>>;
    fn one_index_to_zero(&mut self);
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

    fn one_index_to_zero(&mut self) {
        self.edges
            .iter_mut()
            .for_each(|v| v.iter_mut().for_each(|x| *x -= 1))
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

    fn one_index_to_zero(&mut self) {
        self.points.iter_mut().for_each(|x| *x -= 1)
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

    fn one_index_to_zero(&mut self) {
        self.points.iter_mut().for_each(|x| *x -= 1)
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

    fn one_index_to_zero(&mut self) {
        match self {
            Constraint::DigraphStab(c) => c.one_index_to_zero(),
            Constraint::SetStab(c) => c.one_index_to_zero(),
            Constraint::TupleStab(c) => c.one_index_to_zero(),
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

pub fn build_constraints(constraints: &[Constraint]) -> Vec<Box<dyn Refiner<PartitionState>>> {
    constraints.iter().map(|x| x.build_refiner()).collect()
}
pub fn read_problem<R: BufRead>(prob: &mut R) -> Result<Problem> {
    let mut line = String::new();
    let _ = prob.read_line(&mut line)?;
    let mut parsed: Problem = serde_json::from_str(&line)?;
    for c in &mut parsed.constraints {
        c.one_index_to_zero();
    }
    Ok(parsed)
}
