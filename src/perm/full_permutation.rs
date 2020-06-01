//! Digraphs
//!
//! This crate implements permutations on integers

use super::Permutation;
use serde::{Deserialize, Serialize};
use std::cell::RefCell;
use std::cmp::max;
use std::rc::Rc;

/// Represents a permutation
/// The vals are reference counted and stored to allow for easy copy
/// The inverse is also stored in an option, so it can be cached.
/// The RefCell is needed to ensure interior mutability and compliance
/// with the Permutation API
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct FullPermutation {
    vals: Rc<Vec<usize>>,
    invvals: RefCell<Option<Rc<Vec<usize>>>>,
}

impl Permutation for FullPermutation {
    fn apply(&self, x: usize) -> usize {
        if x < self.vals.len() {
            self.vals[x]
        } else {
            x
        }
    }

    fn collapse(&self) -> FullPermutation {
        self.clone()
    }
}

impl FullPermutation {
    /// Get the identity permutation
    pub fn id() -> Self {
        Self {
            vals: Rc::new(Vec::new()),
            invvals: RefCell::new(Some(Rc::new(Vec::new()))),
        }
    }

    pub fn is_id(&self) -> bool {
        self.vals.is_empty()
    }

    pub fn multiply(&self, other: &FullPermutation) -> FullPermutation {
        if self.is_id() {
            other.clone()
        } else if other.is_id() {
            self.clone()
        } else {
            let size = max(self.lmp().unwrap_or(0), other.lmp().unwrap_or(0));
            debug_assert!(size > 0);
            let v = (0..=size).map(|x| self.and_then(other).apply(x)).collect();
            FullPermutation::from_vec(v)
        }
    }

    /// Create a permutation based on `vals`.
    /// Produces a permutation which maps i to vals\[i\], and acts as the
    /// identity for i >= vals.len()
    /// Requires: vals is a permutation on 0..vals.len()
    pub fn from_vec(mut vals: Vec<usize>) -> Self {
        while !vals.is_empty() && vals[vals.len() - 1] == vals.len() - 1 {
            vals.pop();
        }

        if cfg!(debug_assertions) {
            let mut val_cpy = vals.clone();
            val_cpy.sort();
            for i in val_cpy.into_iter().enumerate() {
                assert_eq!(i.0, i.1)
            }
        }
        Self {
            vals: Rc::new(vals),
            invvals: RefCell::new(None),
        }
    }

    pub fn as_vec(&self) -> &Vec<usize> {
        &self.vals
    }

    fn make_inverse(vals: Rc<Vec<usize>>, invvals: Rc<Vec<usize>>) -> Self {
        Self {
            vals: invvals,
            invvals: RefCell::new(Some(vals)),
        }
    }

    pub fn inv(&self) -> Self {
        if self.invvals.borrow().is_some() {
            return FullPermutation::make_inverse(
                self.vals.clone(),
                self.invvals.borrow().clone().unwrap(),
            );
        }

        let mut v = vec![0; self.vals.len()];
        for i in 0..self.vals.len() {
            v[self.vals[i]] = i;
        }

        let ptr = Rc::new(v);

        *self.invvals.borrow_mut() = Some(ptr.clone());

        FullPermutation::make_inverse(self.vals.clone(), ptr)
    }

    pub fn lmp(&self) -> Option<usize> {
        if self.is_id() {
            None
        } else {
            Some(self.vals.len() - 1)
        }
    }
}

impl PartialEq for FullPermutation {
    fn eq(&self, other: &Self) -> bool {
        self.vals == other.vals
    }
}

impl PartialOrd for FullPermutation {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.vals.cmp(&other.vals))
    }
}

impl std::hash::Hash for FullPermutation {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.vals.hash(state);
    }
}

impl From<Vec<usize>> for FullPermutation {
    fn from(v: Vec<usize>) -> Self {
        FullPermutation::from_vec(v)
    }
}

#[cfg(test)]
mod tests {
    use super::{FullPermutation, Permutation};
    #[test]
    fn id_perm() {
        assert_eq!(FullPermutation::id(), FullPermutation::id());
        assert_eq!(
            FullPermutation::id(),
            FullPermutation::from_vec(vec![0, 1, 2])
        );
    }

    #[test]
    fn leq_perm() {
        assert!(FullPermutation::id() <= FullPermutation::id());
        assert!(!(FullPermutation::id() < FullPermutation::id()));
        assert!(FullPermutation::id() <= FullPermutation::from_vec(vec![0, 1, 2]));
        assert!(!(FullPermutation::id() < FullPermutation::from_vec(vec![0, 1, 2])));

        let id = FullPermutation::id();
        let cycle = FullPermutation::from_vec(vec![1, 2, 0]);
        assert!(id < cycle);
        assert!(!(id > cycle));
    }

    #[test]
    fn not_eq_perm() {
        assert_ne!(
            FullPermutation::id(),
            FullPermutation::from_vec(vec![2, 1, 0])
        );
    }

    #[test]
    fn apply_perm() {
        let id = FullPermutation::id();
        let cycle = FullPermutation::from_vec(vec![1, 2, 0]);

        assert_eq!(0, id.apply(0));
        assert_eq!(1, id.apply(1));
        assert_eq!(1, cycle.apply(0));
        assert_eq!(2, cycle.apply(1));
        assert_eq!(0, cycle.apply(2));
        assert_eq!(3, cycle.apply(3));
    }

    #[test]
    fn mult_perm() {
        let id = FullPermutation::id();
        let cycle = FullPermutation::from_vec(vec![1, 2, 0]);
        let cycle2 = FullPermutation::from_vec(vec![2, 0, 1]);

        let id = &id;
        let cycle = &cycle;
        let cycle2 = &cycle2;

        assert_eq!(*id, id.and_then(id).collapse());
        assert_eq!(*cycle, cycle.and_then(id).collapse());
        assert_eq!(*cycle, id.and_then(cycle).collapse());
        assert_eq!(*cycle2, cycle.and_then(cycle).collapse());
        assert_eq!(*id, cycle.and_then(cycle).and_then(cycle).collapse());
        assert_ne!(*cycle, cycle.and_then(cycle).collapse());
        assert_eq!(*cycle, cycle.pow(1).collapse());
        assert_eq!(cycle.pow(-1).collapse(), cycle.and_then(cycle).collapse());
        assert_eq!(cycle.pow(-2).collapse(), *cycle);
        assert_eq!(cycle.pow(3).collapse(), *id);
        assert_eq!(cycle.pow(10).collapse(), *cycle);
    }
    #[test]
    fn div_perm() {
        let id = FullPermutation::id();
        let cycle = FullPermutation::from_vec(vec![1, 2, 0]);
        let cycle2 = FullPermutation::from_vec(vec![2, 0, 1]);

        let id = &id;
        let cycle = &cycle;
        let cycle2 = &cycle2;

        assert_eq!(*id, id.divide(id).collapse());
        assert_eq!(*cycle, cycle.divide(id).collapse());
        assert_eq!(*cycle2, id.divide(cycle).collapse());
        assert_eq!(*cycle, id.divide(cycle2).collapse());
        assert_eq!(*id, cycle.divide(cycle).collapse());
        assert_eq!(*cycle, id.divide(cycle2).collapse());
        assert_eq!(*cycle2, id.divide(cycle).collapse());
    }
}
