use super::super::state::State;
use super::Refiner;
use crate::vole::trace;
use crate::{perm::Permutation, vole::backtracking::Backtrack};
use std::{
    collections::{HashMap, HashSet},
    rc::Rc,
};

pub struct SetTransporter {
    set_left: Rc<HashSet<usize>>,
    set_right: Rc<HashSet<usize>>,
}

impl SetTransporter {
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

impl Refiner for SetTransporter {
    fn name(&self) -> String {
        if self.is_group() {
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

impl Backtrack for SetTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}

// Tuple is stored as a hash map, from value to position in list
pub struct TupleTransporter {
    tuplemap_left: HashMap<usize, usize>,
    tuple_left: Vec<usize>,
    tuplemap_right: HashMap<usize, usize>,
    tuple_right: Vec<usize>,
}

impl TupleTransporter {
    pub fn new_stabilizer(tuple: Vec<usize>) -> Self {
        Self::new_transporter(tuple.clone(), tuple)
    }

    pub fn new_transporter(tuple_left: Vec<usize>, tuple_right: Vec<usize>) -> Self {
        let mut tuplemap_left = HashMap::<usize, usize>::new();
        let mut tuplemap_right = HashMap::<usize, usize>::new();

        // If a value occurs multiple times, only the last one will be stored,
        // but this will lead to the same result anyway once checking occurs
        for (i, val) in tuple_left.iter().enumerate() {
            tuplemap_left.insert(*val, i + 1);
        }

        for (i, val) in tuple_right.iter().enumerate() {
            tuplemap_right.insert(*val, i + 1);
        }

        Self {
            tuplemap_left,
            tuple_left,
            tuplemap_right,
            tuple_right,
        }
    }
}

impl Refiner for TupleTransporter {
    fn name(&self) -> String {
        if self.is_group() {
            format!("TupleTransporter of {:?}", self.tuple_left)
        } else {
            format!(
                "TupleTransporter of {:?} -> {:?}",
                self.tuple_left, self.tuple_right
            )
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        if self.tuple_left.len() != self.tuple_right.len() {
            return false;
        }

        self.tuple_left
            .iter()
            .zip(self.tuple_right.iter())
            .all(|(&x, &y)| p.apply(x) == y)
    }

    fn refine_begin_left(&mut self, state: &mut State) -> trace::Result<()> {
        state.refine_partition_by(|x| self.tuplemap_left.get(x).unwrap_or(&0))?;
        Ok(())
    }

    fn refine_begin_right(&mut self, state: &mut State) -> trace::Result<()> {
        state.refine_partition_by(|x| self.tuplemap_right.get(x).unwrap_or(&0))?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        self.tuple_left == self.tuple_right
    }
}

impl Backtrack for TupleTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
}
