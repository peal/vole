use super::super::state::State;
use super::Refiner;
use crate::vole::trace;
use crate::{perm::Permutation, vole::backtracking::Backtrack};
use std::collections::{HashMap, HashSet};

pub struct SetStabilizer {
    set: HashSet<usize>,
}

impl SetStabilizer {
    pub fn new(set: HashSet<usize>) -> Self {
        Self { set }
    }
}

impl<T: State> Refiner<T> for SetStabilizer {
    fn name(&self) -> String {
        format!("SetStabilizer of {:?}", self.set)
    }

    fn check(&self, p: &Permutation) -> bool {
        self.set
            .iter()
            .cloned()
            .all(|x| self.set.contains(&(p.apply(x))))
    }

    fn refine_begin(&mut self, state: &mut T) -> trace::Result<()> {
        state.refine_partition_by(|x| self.set.contains(x))?;
        Ok(())
    }
}

impl Backtrack for SetStabilizer {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}

// Tuple is stored as a hash map, from value to position in list
pub struct TupleStabilizer {
    tuplemap: HashMap<usize, usize>,
    tuple: Vec<usize>,
}

impl TupleStabilizer {
    pub fn new(tuple: Vec<usize>) -> Self {
        let mut tuplemap = HashMap::<usize, usize>::new();
        // If a value occurs multiple times, only the last one will be stored,
        // but this will lead to the same result anyway.
        // We use '+1', so 0 is free to use in refine_begin as a blank value
        for (i, val) in tuple.iter().enumerate() {
            tuplemap.insert(*val, i + 1);
        }
        Self { tuplemap, tuple }
    }
}

impl<T: State> Refiner<T> for TupleStabilizer {
    fn name(&self) -> String {
        format!("TupleStabilizer of {:?}", self.tuple)
    }

    fn check(&self, p: &Permutation) -> bool {
        self.tuple.iter().cloned().all(|x| p.apply(x) == x)
    }

    fn refine_begin(&mut self, state: &mut T) -> trace::Result<()> {
        state.refine_partition_by(|x| self.tuplemap.get(x).unwrap_or(&0))?;
        Ok(())
    }
}

impl Backtrack for TupleStabilizer {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}
