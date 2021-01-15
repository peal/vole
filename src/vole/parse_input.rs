use serde::{Deserialize, Serialize};

use crate::datastructures::digraph::Digraph;

use super::refiners::digraph::DigraphStabilizer;
use super::refiners::simple::SetStabilizer;
use super::refiners::simple::TupleStabilizer;
use super::refiners::Refiner;

use anyhow::Result;

use std::io::BufRead;

/// Translate a GAP description of a refiner to a [Refiner] object
trait RefinerDescription {
    /// Build a [Box<dyn Refiner>]
    fn build_refiner(&self) -> Box<dyn Refiner>;
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphStab {
    edges: Vec<Vec<usize>>,
}

impl RefinerDescription for DigraphStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let edges = self
            .edges
            .iter()
            .map(|v| v.iter().map(|x| *x - 1).collect())
            .collect();

        Box::new(DigraphStabilizer::new(Digraph::from_vec(edges)))
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SetStab {
    points: Vec<usize>,
}

impl RefinerDescription for SetStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self.points.iter().map(|&x| x - 1).collect();
        Box::new(SetStabilizer::new_stabilizer(points))
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct TupleStab {
    points: Vec<usize>,
}

impl RefinerDescription for TupleStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self.points.iter().map(|&x| x - 1).collect();
        Box::new(TupleStabilizer::new(points))
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
    let parsed: Problem = serde_json::from_str(&line)?;
    Ok(parsed)
}
