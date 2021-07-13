use serde::{Deserialize, Serialize};

use crate::datastructures::digraph::Digraph;

use super::refiners::simple::SetTransporter;
use super::refiners::simple::TupleTransporter;
use super::refiners::symmetricgrp::InSymmetricGrp;
use super::refiners::Refiner;
use super::refiners::{
    digraph::DigraphTransporter,
    simple::{SetSetTransporter, SetTupleTransporter},
};

use anyhow::{Context, Result};

use std::{io::BufRead, sync::Arc};

/// Translate a GAP description of a refiner to a [Refiner] object. This mainly
/// involves moving from GAP's 1-indexed structures to a 0-indexed structure.
trait RefinerDescription {
    /// Build a [Box<dyn Refiner>]
    fn build_refiner(&self) -> Box<dyn Refiner>;
}

/// Store a Digraph Stabilizer constraint sent from GAP
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

        Box::new(DigraphTransporter::new_stabilizer(Arc::new(
            Digraph::from_vec(edges),
        )))
    }
}

/// Store a Digraph Transporter constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct DigraphTransport {
    edges_left: Vec<Vec<usize>>,
    edges_right: Vec<Vec<usize>>,
}

impl RefinerDescription for DigraphTransport {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let edges_left = self
            .edges_left
            .iter()
            .map(|v| v.iter().map(|x| *x - 1).collect())
            .collect();

        let edges_right = self
            .edges_right
            .iter()
            .map(|v| v.iter().map(|x| *x - 1).collect())
            .collect();

        Box::new(DigraphTransporter::new_transporter(
            Arc::new(Digraph::from_vec(edges_left)),
            Arc::new(Digraph::from_vec(edges_right)),
        ))
    }
}

/// Store a Set Stabilizer constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetStab {
    points: Vec<usize>,
}

impl RefinerDescription for SetStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self.points.iter().map(|&x| x - 1).collect();
        Box::new(SetTransporter::new_stabilizer(points))
    }
}

/// Store a Set Transporter constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetTransport {
    left_points: Vec<usize>,
    right_points: Vec<usize>,
}

impl RefinerDescription for SetTransport {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let left_points = self.left_points.iter().map(|&x| x - 1).collect();
        let right_points = self.right_points.iter().map(|&x| x - 1).collect();
        Box::new(SetTransporter::new_transporter(left_points, right_points))
    }
}

/// Store a Tuple Stabilizer constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct TupleStab {
    points: Vec<usize>,
}

impl RefinerDescription for TupleStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self.points.iter().map(|&x| x - 1).collect();
        Box::new(TupleTransporter::new_stabilizer(points))
    }
}

/// Store a Tuple Transporter constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct TupleTransport {
    left_points: Vec<usize>,
    right_points: Vec<usize>,
}

impl RefinerDescription for TupleTransport {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let left_points = self.left_points.iter().map(|&x| x - 1).collect();
        let right_points = self.right_points.iter().map(|&x| x - 1).collect();
        Box::new(TupleTransporter::new_transporter(left_points, right_points))
    }
}

/// Store a Set Set Stabilizer constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetSetStab {
    points: Vec<Vec<usize>>,
}

impl RefinerDescription for SetSetStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self
            .points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        Box::new(SetSetTransporter::new_stabilizer(points))
    }
}

/// Store a Set Set Transporter constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetSetTransport {
    left_points: Vec<Vec<usize>>,
    right_points: Vec<Vec<usize>>,
}

impl RefinerDescription for SetSetTransport {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let left_points = self
            .left_points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        let right_points = self
            .right_points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        Box::new(SetSetTransporter::new_transporter(
            left_points,
            right_points,
        ))
    }
}

/// Store a Set Tuple Stabilizer constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetTupleStab {
    points: Vec<Vec<usize>>,
}

impl RefinerDescription for SetTupleStab {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self
            .points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        Box::new(SetTupleTransporter::new_stabilizer(points))
    }
}

/// Store a Set Set Transporter constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct SetTupleTransport {
    left_points: Vec<Vec<usize>>,
    right_points: Vec<Vec<usize>>,
}

impl RefinerDescription for SetTupleTransport {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let left_points = self
            .left_points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        let right_points = self
            .right_points
            .iter()
            .map(|x| x.iter().map(|&y| y - 1).collect())
            .collect();
        Box::new(SetTupleTransporter::new_transporter(
            left_points,
            right_points,
        ))
    }
}

/// Store a Symmetric Group constraint sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct InSymmetricGroup {
    points: Vec<usize>,
}

impl RefinerDescription for InSymmetricGroup {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        let points = self.points.iter().map(|&x| x - 1).collect();
        Box::new(InSymmetricGrp::new_symmetric_group(points))
    }
}

/// Store a Refiner represented a GraphBacktracking GAP object, sent from GAP
#[derive(Debug, Deserialize, Serialize)]
pub struct GapRefiner {
    gap_id: usize,
}

impl RefinerDescription for GapRefiner {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        Box::new(super::refiners::gaprefiner::GapRefiner::new(self.gap_id))
    }
}

/// Store all constraints which can come from GAP
#[allow(missing_docs)]
#[derive(Debug, Deserialize, Serialize)]
pub enum Constraint {
    DigraphStab(DigraphStab),
    DigraphTransport(DigraphTransport),
    SetStab(SetStab),
    SetTransport(SetTransport),
    TupleStab(TupleStab),
    TupleTransport(TupleTransport),
    SetSetStab(SetSetStab),
    SetSetTransport(SetSetTransport),
    SetTupleStab(SetTupleStab),
    SetTupleTransport(SetTupleTransport),
    InSymmetricGroup(InSymmetricGroup),
    GapRefiner(GapRefiner),
}

impl RefinerDescription for Constraint {
    fn build_refiner(&self) -> Box<dyn Refiner> {
        match self {
            Self::DigraphStab(c) => c.build_refiner(),
            Self::SetStab(c) => c.build_refiner(),
            Self::TupleStab(c) => c.build_refiner(),
            Self::SetTupleStab(c) => c.build_refiner(),
            Self::SetSetStab(c) => c.build_refiner(),
            Self::GapRefiner(c) => c.build_refiner(),
            Self::DigraphTransport(c) => c.build_refiner(),
            Self::SetTransport(c) => c.build_refiner(),
            Self::TupleTransport(c) => c.build_refiner(),
            Self::SetSetTransport(c) => c.build_refiner(),
            Self::SetTupleTransport(c) => c.build_refiner(),
            Self::InSymmetricGroup(c) => c.build_refiner(),
        }
    }
}

/// Overall configuration for problem to be solved
#[derive(Debug, Deserialize, Serialize)]
pub struct ProblemConfig {
    /// The problem should be solved on the set [1..`points`]
    pub points: usize,
    /// Find only a single solution
    pub find_single: bool,
    /// Find canonical image
    pub find_canonical: bool,
    /// Only perform root search
    pub root_search: bool,
}

/// The Problem to be solved
#[derive(Debug, Deserialize, Serialize)]
pub struct Problem {
    /// Configuration
    pub config: ProblemConfig,
    /// List of constraints
    pub constraints: Vec<Constraint>,
}

/// Convert GAP definition of Constraints into Vole objects
pub fn build_constraints(constraints: &[Constraint]) -> Vec<Box<dyn Refiner>> {
    constraints.iter().map(|x| x.build_refiner()).collect()
}

/// Read a `Problem` from an input stream (Problem should be in JSON)
pub fn read_problem<R: BufRead>(prob: &mut R) -> Result<Problem> {
    let mut line = String::new();
    let _ = prob.read_line(&mut line)?;
    let parsed: Problem = serde_json::from_str(&line).context(
        "Invalid problem specification. Does one of your constraints have the wrong argument type?",
    )?;
    assert!(
        parsed.config.points > 1,
        "Problems must have at least two points"
    );
    Ok(parsed)
}
