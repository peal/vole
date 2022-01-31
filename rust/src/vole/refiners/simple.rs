use super::Refiner;

use super::{super::domain_state::DomainState, Side};
use crate::{
    datastructures::{digraph::Digraph, sortedvec::SortedVec},
    vole::trace,
};
use crate::{perm::Permutation, vole::backtracking::Backtrack};
use std::{cmp::Ordering, collections::HashMap, rc::Rc};

pub struct SetTransporter {
    set_left: Rc<SortedVec<usize>>,
    set_right: Rc<SortedVec<usize>>,
}

impl SetTransporter {
    pub fn new_transporter(set_left: SortedVec<usize>, set_right: SortedVec<usize>) -> Self {
        Self {
            set_left: Rc::new(set_left),
            set_right: Rc::new(set_right),
        }
    }

    pub fn new_stabilizer(set: SortedVec<usize>) -> Self {
        let r = Rc::new(set);
        Self {
            set_left: r.clone(),
            set_right: r,
        }
    }

    fn image(&self, p: &Permutation, side: Side) -> SortedVec<usize> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        set.iter().map(|&x| p.apply(x)).collect()
    }

    fn compare(&self, lhs: &SortedVec<usize>, rhs: &SortedVec<usize>) -> Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for SetTransporter {
    gen_any_image_compare!(SortedVec<usize>);

    fn name(&self) -> String {
        if self.is_group() {
            format!("SetStabilizer of {:?}", self.set_left)
        } else {
            format!("SetTransporter of {:?} -> {:?}", self.set_left, self.set_right)
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        self.set_left
            .as_ref()
            .into_iter()
            .all(|x| self.set_right.contains(&(p.apply(*x))))
    }

    fn refine_begin(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        state.add_invariant_fact(set.len())?;

        state.base_refine_partition_by(|x| set.contains(x))?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        Rc::ptr_eq(&self.set_left, &self.set_right)
    }
}

impl Backtrack for SetTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
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

    fn image(&self, p: &Permutation, side: Side) -> Vec<usize> {
        let tuple = match side {
            Side::Left => &self.tuple_left,
            Side::Right => &self.tuple_right,
        };
        tuple.iter().map(|&x| p.apply(x)).collect()
    }

    fn compare(&self, lhs: &[usize], rhs: &[usize]) -> Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for TupleTransporter {
    gen_any_image_compare!(Vec<usize>);

    fn name(&self) -> String {
        if self.is_group() {
            format!("TupleTransporter of {:?}", self.tuple_left)
        } else {
            format!("TupleTransporter of {:?} -> {:?}", self.tuple_left, self.tuple_right)
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

    fn refine_begin(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let tuplemap = match side {
            Side::Left => &self.tuplemap_left,
            Side::Right => &self.tuplemap_right,
        };

        state.add_invariant_fact(match side {
            Side::Left => self.tuple_left.len(),
            Side::Right => self.tuple_right.len(),
        })?;

        state.base_refine_partition_by(|x| tuplemap.get(x).unwrap_or(&0))?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        self.tuple_left == self.tuple_right
    }
}

impl Backtrack for TupleTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
}

pub struct SetSetTransporter {
    set_left: Rc<SortedVec<SortedVec<usize>>>,
    set_right: Rc<SortedVec<SortedVec<usize>>>,
}

impl SetSetTransporter {
    pub fn new_transporter(set_left: SortedVec<SortedVec<usize>>, set_right: SortedVec<SortedVec<usize>>) -> Self {
        Self {
            set_left: Rc::new(set_left),
            set_right: Rc::new(set_right),
        }
    }

    pub fn new_stabilizer(set: SortedVec<SortedVec<usize>>) -> Self {
        let r = Rc::new(set);
        Self {
            set_left: r.clone(),
            set_right: r,
        }
    }

    fn image(&self, p: &Permutation, side: Side) -> SortedVec<SortedVec<usize>> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        set.iter().map(|x| x.iter().map(|&y| p.apply(y)).collect()).collect()
    }

    fn compare(&self, lhs: &SortedVec<SortedVec<usize>>, rhs: &SortedVec<SortedVec<usize>>) -> Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for SetSetTransporter {
    gen_any_image_compare!(SortedVec<SortedVec<usize>>);

    fn name(&self) -> String {
        if self.is_group() {
            format!("SetSetStabilizer of {:?}", self.set_left)
        } else {
            format!("SetSetTransporter of {:?} -> {:?}", self.set_left, self.set_right)
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        if self.set_left.len() != self.set_right.len() {
            return false;
        }

        for set in &*self.set_left {
            let image: SortedVec<usize> = set.iter().map(|&x| p.apply(x)).collect();
            if !self.set_right.contains(&image) {
                return false;
            }
        }
        true
    }

    fn refine_begin(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        // Record: number of sets in the set, whether set contains the empty set
        state.add_invariant_fact(set.len())?;
        state.add_invariant_fact(set.iter().any(|x| x.is_empty()))?;

        if set.is_empty() {
            return Ok(());
        }

        let base = state.partition().base_domain_size();
        let extended = state.partition().extended_domain_size();
        let _ = state.extend_partition(set.len());

        let mut v: Vec<Vec<usize>> = vec![vec![]; extended + set.len()];
        for (s, i) in set.iter().enumerate() {
            for &val in i {
                debug_assert!(val < base);
                v[val].push(s + extended);
            }
        }

        state.add_graph(&Digraph::from_vec(v));
        Ok(())
    }

    fn is_group(&self) -> bool {
        self.check(&Permutation::id())
    }
}

impl Backtrack for SetSetTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
}

pub struct SetTupleTransporter {
    set_left: Rc<SortedVec<Vec<usize>>>,
    set_right: Rc<SortedVec<Vec<usize>>>,
}

impl SetTupleTransporter {
    pub fn new_transporter(set_left: SortedVec<Vec<usize>>, set_right: SortedVec<Vec<usize>>) -> Self {
        Self {
            set_left: Rc::new(set_left),
            set_right: Rc::new(set_right),
        }
    }

    pub fn new_stabilizer(set: SortedVec<Vec<usize>>) -> Self {
        let r = Rc::new(set);
        Self {
            set_left: r.clone(),
            set_right: r,
        }
    }

    fn image(&self, p: &Permutation, side: Side) -> SortedVec<Vec<usize>> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        set.iter().map(|x| x.iter().map(|&y| p.apply(y)).collect()).collect()
    }

    fn compare(&self, lhs: &SortedVec<Vec<usize>>, rhs: &SortedVec<Vec<usize>>) -> Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for SetTupleTransporter {
    gen_any_image_compare!(SortedVec<Vec<usize>>);

    fn name(&self) -> String {
        if self.is_group() {
            format!("SetTupleStabilizer of {:?}", self.set_left)
        } else {
            format!("SetTupleTransporter of {:?} -> {:?}", self.set_left, self.set_right)
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        if self.set_left.len() != self.set_right.len() {
            return false;
        }

        for set in &*self.set_left {
            let image: Vec<usize> = set.iter().map(|&x| p.apply(x)).collect();
            if !self.set_right.contains(&image) {
                return false;
            }
        }
        true
    }

    fn refine_begin(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        let set = match side {
            Side::Left => &self.set_left,
            Side::Right => &self.set_right,
        };

        // Record: number of tuples in set, whether set contains empty tuple
        state.add_invariant_fact(set.len())?;
        state.add_invariant_fact(set.iter().any(|x| x.len() == 0))?;

        let base = state.partition().base_domain_size();
        let extended = state.partition().extended_domain_size();

        // We build graph first, then we count number of vertices we used
        // We will start colouring just past end of previous vertices
        let extra_points = set.iter().map(|x| x.len()).sum();
        if extra_points == 0 {
            return Ok(());
        }
        let total_new_size = extended + extra_points;
        let mut colouring = vec![0usize; total_new_size];
        let mut graph: Vec<Vec<usize>> = vec![vec![]; total_new_size];

        let mut new_vert = extended;

        for tuple in set.iter() {
            for (pos, &val) in tuple.iter().enumerate() {
                debug_assert!(val < base);
                colouring[new_vert] = pos + 1;
                graph[val].push(new_vert);
                if pos > 0 {
                    graph[new_vert].push(new_vert - 1)
                }
                new_vert += 1;
            }
        }

        assert!(new_vert == total_new_size);

        let new_part = state.extend_partition(extra_points);

        state.refine_partition_cell_by(new_part, |x| colouring[*x])?;

        state.add_graph(&Digraph::from_vec(graph));
        Ok(())
    }

    fn is_group(&self) -> bool {
        self.check(&Permutation::id())
    }
}

impl Backtrack for SetTupleTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
}
