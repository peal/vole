//! Digraphs
//!
//! This crate implements permutations on integers

extern crate serde;
extern crate serde_json;

extern crate serde_derive;
use serde_derive::{Deserialize, Serialize};

use std::cmp::max;
use std::rc::Rc;

/// Represents a permutation
#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash, Deserialize, Serialize)]
pub struct Permutation {
    vals: Rc<Vec<usize>>,
}

impl Permutation {
    /// Get the identity permutation
    pub fn id() -> Permutation {
        Permutation {
            vals: Rc::new(Vec::new()),
        }
    }

    /// Create a permutation based on `vals`.
    /// Produces a permutation which maps i to vals\[i\], and acts as the
    /// identity for i >= vals.len()
    /// Requires: vals is a permutation on 0..vals.len()
    pub fn from_vec(mut vals: Vec<usize>) -> Permutation {
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
        Permutation {
            vals: Rc::new(vals),
        }
    }

    pub fn inv(&self) -> Permutation {
        let mut v = vec![0; self.vals.len()];
        for i in 0..self.vals.len() {
            v[self.vals[i]] = i;
        }
        Permutation { vals: Rc::new(v) }
    }

    pub fn is_id(&self) -> bool {
        self.vals.is_empty()
    }

    pub fn lmp(&self) -> Option<usize> {
        if self.is_id() {
            None
        } else {
            Some(self.vals.len() - 1)
        }
    }
}

impl std::ops::BitXor<&Permutation> for usize {
    type Output = usize;

    fn bitxor(self, perm: &Permutation) -> Self::Output {
        if self < perm.vals.len() {
            perm.vals[self]
        } else {
            self
        }
    }
}

impl std::ops::BitXor<isize> for &Permutation {
    type Output = Permutation;

    fn bitxor(self, index: isize) -> Self::Output {
        if index == 0 {
            Permutation::id()
        } else if index == 1 {
            self.clone()
        } else if index == -1 {
            self.inv()
        } else if index < 0 {
            (&(self.inv())) ^ (-index)
        } else {
            let mut p = self.clone();
            for _ in 1..index {
                p = p * self;
            }
            p
        }
    }
}

impl std::ops::Mul<&Permutation> for &Permutation {
    type Output = Permutation;

    #[allow(clippy::suspicious_arithmetic_impl)]
    fn mul(self, other: &Permutation) -> Self::Output {
        if self.is_id() {
            other.clone()
        } else if other.is_id() {
            self.clone()
        } else {
            let size = max(self.lmp().unwrap_or(0), other.lmp().unwrap_or(0));
            debug_assert!(size > 0);
            let v = (0..=size).map(|x| (x ^ self) ^ other).collect();
            Permutation::from_vec(v)
        }
    }
}

impl std::ops::Mul<Permutation> for Permutation {
    type Output = Permutation;
    fn mul(self, other: Permutation) -> Self::Output {
        &self * &other
    }
}

impl std::ops::Mul<&Permutation> for Permutation {
    type Output = Permutation;
    fn mul(self, other: &Permutation) -> Self::Output {
        &self * other
    }
}
impl std::ops::Mul<Permutation> for &Permutation {
    type Output = Permutation;
    fn mul(self, other: Permutation) -> Self::Output {
        self * &other
    }
}

#[cfg(test)]
mod tests {
    use crate::Permutation;
    #[test]
    fn id_perm() {
        assert_eq!(Permutation::id(), Permutation::id());
        assert_eq!(Permutation::id(), Permutation::from_vec(vec![0, 1, 2]));
    }

    #[test]
    fn leq_perm() {
        assert!(Permutation::id() <= Permutation::id());
        assert!(!(Permutation::id() < Permutation::id()));
        assert!(Permutation::id() <= Permutation::from_vec(vec![0, 1, 2]));
        assert!(!(Permutation::id() < Permutation::from_vec(vec![0, 1, 2])));

        let id = Permutation::id();
        let cycle = Permutation::from_vec(vec![1, 2, 0]);
        assert!(id < cycle);
        assert!(!(id > cycle));
    }

    #[test]
    fn not_eq_perm() {
        assert_ne!(Permutation::id(), Permutation::from_vec(vec![2, 1, 0]));
    }

    #[test]
    fn apply_perm() {
        let id = Permutation::id();
        let cycle = Permutation::from_vec(vec![1, 2, 0]);

        assert_eq!(0, 0 ^ &id);
        assert_eq!(1, 1 ^ &id);
        assert_eq!(1, 0 ^ &cycle);
        assert_eq!(2, 1 ^ &cycle);
        assert_eq!(0, 2 ^ &cycle);
        assert_eq!(3, 3 ^ &cycle);
    }

    #[test]
    fn mult_perm() {
        let id = Permutation::id();
        let cycle = Permutation::from_vec(vec![1, 2, 0]);
        let cycle2 = Permutation::from_vec(vec![2, 0, 1]);
        assert_eq!(id, &id * &id);
        assert_eq!(cycle, &cycle * &id);
        assert_eq!(cycle, &id * &cycle);
        assert_eq!(cycle2, &cycle * &cycle);
        assert_eq!(id, &cycle * &cycle * &cycle);
        assert_ne!(cycle, &cycle * &cycle);
        assert_eq!(cycle, (&cycle) ^ 1);
        assert_eq!((&cycle) ^ (-1), &cycle * &cycle);
        assert_eq!((&cycle) ^ (-2), cycle);
        assert_eq!((&cycle) ^ 3, id);
        assert_eq!((&cycle) ^ 10, cycle);
    }
}
