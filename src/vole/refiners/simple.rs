use super::super::state::State;
use super::Refiner;
use crate::vole::trace;
use crate::{perm::Permutation, vole::backtracking::Backtrack};
use std::{
    collections::{HashMap, HashSet},
    rc::Rc,
};

pub struct SetStabilizer {
    set_left: Rc<HashSet<usize>>,
    set_right: Rc<HashSet<usize>>,
}

impl SetStabilizer {
    pub fn new_transporter(set_left: HashSet<usize>, set_right: HashSet<usize>) -> Self {
        Self {
            set_left: Rc::new(set_left),
            set_right: Rc::new(set_right),
        }
    }

    pub fn new_stabilizer(set: HashSet<usize>) -> Self {
        let r = Rc::new(set);
        Self {
            set_left: r.clone(),
            set_right: r,
        }
    }
}

impl Refiner for SetStabilizer {
    fn name(&self) -> String {
        let g: bool = self.is_group();
        if g {
            format!("SetStabilizer of {:?}", self.set_left)
        } else {
            format!(
                "SetTransporter of {:?} -> {:?}",
                self.set_left, self.set_right
            )
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        self.set_left
            .iter()
            .cloned()
            .all(|x| self.set_right.contains(&(p.apply(x))))
    }

    fn refine_begin_left(&mut self, state: &mut State) -> trace::Result<()> {
        state.refine_partition_by(|x| self.set_left.contains(x))?;
        Ok(())
    }

    fn refine_begin_right(&mut self, state: &mut State) -> trace::Result<()> {
        state.refine_partition_by(|x| self.set_right.contains(x))?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        Rc::ptr_eq(&self.set_left, &self.set_right)
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
        // We use '+1', so 0 is free to use in refine_begin_left as a blank value
        for (i, val) in tuple.iter().enumerate() {
            tuplemap.insert(*val, i + 1);
        }
        Self { tuplemap, tuple }
    }
}

impl Refiner for TupleStabilizer {
    fn name(&self) -> String {
        format!("TupleStabilizer of {:?}", self.tuple)
    }

    fn check(&self, p: &Permutation) -> bool {
        self.tuple.iter().cloned().all(|x| p.apply(x) == x)
    }

    fn refine_begin_left(&mut self, state: &mut State) -> trace::Result<()> {
        state.refine_partition_by(|x| self.tuplemap.get(x).unwrap_or(&0))?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        true
    }
}

impl Backtrack for TupleStabilizer {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}
