use serde::{Deserialize, Serialize};

use crate::datastructures::digraph::Digraph;

use super::refiners::digraph::DigraphStabilizer;
use super::refiners::simple::SetStabilizer;
use super::refiners::simple::TupleStabilizer;
use super::refiners::Refiner;

use anyhow::Result;

use std::io::BufRead;

trait RefinerDescription {
    fn build_refiner(&self) -> Box<dyn Refiner>;
    fn one_index_to_zero(&mut self);
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphStab {
    edges: Vec<Vec<usize>>,
}

impl RefinerDescription for DigraphStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
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
    fn build_refiner(&self) -> Box<dyn Refiner> {
        Box::new(SetStabilizer::new_stabilizer(
            self.points.iter().cloned().collect(),
        ))
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
    fn build_refiner(&self) -> Box<dyn Refiner> {
        Box::new(TupleStabilizer::new(self.points.clone()))
    }

    fn one_index_to_zero(&mut self) {
        self.points.iter_mut().for_each(|x| *x -= 1)
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GapRefiner {
    gap_id: usize,
}

impl RefinerDescription for GapRefiner {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        Box::new(super::refiners::gaprefiner::GapRefiner::new(self.gap_id))
    }

    fn one_index_to_zero(&mut self) {}
}

#[derive(Debug, Deserialize, Serialize)]
pub enum Constraint {
    DigraphStab(DigraphStab),
    SetStab(SetStab),
    TupleStab(TupleStab),
    GapRefiner(GapRefiner),
}

impl RefinerDescription for Constraint {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        match self {
            Self::DigraphStab(c) => c.build_refiner(),
            Self::SetStab(c) => c.build_refiner(),
            Self::TupleStab(c) => c.build_refiner(),
            Self::GapRefiner(c) => c.build_refiner(),
        }
    }

    fn one_index_to_zero(&mut self) {
        match self {
            Self::DigraphStab(c) => c.one_index_to_zero(),
            Self::SetStab(c) => c.one_index_to_zero(),
            Self::TupleStab(c) => c.one_index_to_zero(),
            Self::GapRefiner(c) => c.one_index_to_zero(),
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

pub fn build_constraints(constraints: &[Constraint]) -> Vec<Box<dyn Refiner>> {
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
