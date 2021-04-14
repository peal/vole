//! Digraphs
//!
//! This crate implements permutations on integers

// mod randomreplacement;
mod builder;
mod schreiervector;
pub mod utils;

use builder::PermBuilder;

use serde::{Deserialize, Serialize};
use std::cell::RefCell;
use std::cmp::max;
use std::rc::Rc;

/// Represents a permutation
/// The values are reference counted and stored to allow for easy copy
/// The inverse is also stored in an option, so it can be cached.
/// The RefCell is needed to ensure interior mutability and compliance
/// with the Permutation API
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Permutation {
    values: Rc<Vec<usize>>,
    inv_values: RefCell<Option<Rc<Vec<usize>>>>,
}

impl Permutation {
    /// Get the identity permutation
    pub fn id() -> Self {
        Self {
            values: Rc::new(Vec::new()),
            inv_values: RefCell::new(Some(Rc::new(Vec::new()))),
        }
    }

    /// Tests if the permutation is the identity
    /// ```
    /// use rust_vole::perm::Permutation;
    /// assert!(Permutation::id().is_id());
    /// let a = Permutation::from_vec(vec![1, 0]);
    /// assert!(a.multiply(&a).is_id());
    /// ```
    pub fn is_id(&self) -> bool {
        self.values.is_empty()
    }

    /// Get the vector representation of the permutation
    pub fn as_vec(&self) -> &[usize] {
        &self.values[..]
    }

    // Helper to make the inverse
    fn make_inverse(values: Rc<Vec<usize>>, inv_values: Rc<Vec<usize>>) -> Self {
        Self {
            values: inv_values,
            inv_values: RefCell::new(Some(values)),
        }
    }

    /// Applies the permutation to a point
    /// ```
    /// use rust_vole::perm::Permutation;
    /// assert_eq!(Permutation::id().apply(1), 1);
    /// ```
    pub fn apply(&self, x: usize) -> usize {
        if x < self.values.len() {
            self.values[x]
        } else {
            x
        }
    }

    /// Create a permutation based on `values`.
    /// Produces a permutation which maps i to values\[i\], and acts as the
    /// identity for i >= values.len()
    /// Requires: values is a permutation on 0..values.len()
    /// ```
    /// use rust_vole::perm::Permutation;
    /// let a = Permutation::from_vec(vec![1, 0]);
    /// ```
    pub fn from_vec(mut values: Vec<usize>) -> Self {
        while !values.is_empty() && values[values.len() - 1] == values.len() - 1 {
            values.pop();
        }
        //println!("{:?}", values);
        if cfg!(debug_assertions) {
            let mut val_cpy = values.clone();
            val_cpy.sort();
            for i in val_cpy.into_iter().enumerate() {
                assert_eq!(i.0, i.1)
            }
        }
        Self {
            values: Rc::new(values),
            inv_values: RefCell::new(None),
        }
    }

    /// Computes the inverse of a permutation.
    /// Note this also lazily caches the inverse, so subsequent calls should
    /// be extremely quick
    /// ```
    /// use rust_vole::perm::Permutation;
    /// let a = Permutation::from_vec(vec![1, 0]);
    /// assert_eq!(a, a.inv());
    /// ```
    pub fn inv(&self) -> Self {
        if self.inv_values.borrow().is_some() {
            return Self::make_inverse(
                self.values.clone(),
                self.inv_values.borrow().clone().unwrap(),
            );
        }

        let mut v = vec![0; self.values.len()];
        for i in 0..self.values.len() {
            v[self.values[i]] = i;
        }

        let ptr = Rc::new(v);

        *self.inv_values.borrow_mut() = Some(ptr.clone());

        Self::make_inverse(self.values.clone(), ptr)
    }

    /// Multiplies two permutations
    /// ```
    /// use rust_vole::perm::Permutation;
    /// let a = Permutation::from_vec(vec![0, 2, 1]);
    /// let b = a.inv();
    /// assert_eq!(a.multiply(&b), Permutation::id());
    /// ```
    pub fn multiply(&self, other: &Self) -> Self {
        if self.is_id() {
            if other.is_id() {
                return self.clone();
            }
            let size = other.lmp().unwrap();
            Self::from_vec((0..=size).map(|x| other.apply(x)).collect())
        } else if other.is_id() {
            self.clone()
        } else {
            let size = max(self.lmp().unwrap_or(0), other.lmp().unwrap_or(0));
            debug_assert!(size > 0);
            let v = (0..=size).map(|x| self.apply(other.apply(x))).collect();
            Self::from_vec(v)
        }
    }

    /// Computes the n-th power of a a permutation
    /// ```
    /// use rust_vole::perm::Permutation;
    /// let a = Permutation::from_vec(vec![2, 0, 1]);
    /// assert_eq!(a.pow(3), Permutation::id());
    /// assert_eq!(a.pow(-1), a.inv());
    /// ```
    pub fn pow(&self, pow: isize) -> Self {
        self.build_pow(pow).collapse()
    }

    /// Computes f * g^-1
    pub fn divide(&self, other: &Self) -> Self {
        self.build_divide(other).collapse()
    }

    pub fn lmp(&self) -> Option<usize> {
        if self.values.is_empty() {
            None
        } else {
            Some(self.values.len() - 1)
        }
    }
}

impl PermBuilder for Permutation {
    fn build_apply(&self, x: usize) -> usize {
        if x < self.values.len() {
            self.values[x]
        } else {
            x
        }
    }

    fn collapse(&self) -> Permutation {
        self.clone()
    }
}

impl PartialEq for Permutation {
    fn eq(&self, other: &Self) -> bool {
        self.values == other.values
    }
}

impl PartialOrd for Permutation {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.values.cmp(&other.values))
    }
}

impl std::hash::Hash for Permutation {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.values.hash(state);
    }
}

impl From<Vec<usize>> for Permutation {
    fn from(v: Vec<usize>) -> Self {
        Self::from_vec(v)
    }
}

#[allow(clippy::eq_op, clippy::neg_cmp_op_on_partial_ord)]
#[cfg(test)]
mod tests {
    use super::Permutation;
    #[test]
    fn id_perm() {
        assert_eq!(Permutation::id(), Permutation::id());
        assert_eq!(Permutation::id(), Permutation::from_vec(vec![0, 1, 2]));
    }

    #[test]
    fn test_is_id() {
        let perm = Permutation::from_vec(vec![0, 1, 2]);
        assert!(perm.is_id());
        let perm = Permutation::from_vec(vec![0, 2, 1, 4, 3]);
        assert!(perm.multiply(&perm.inv()).is_id())
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

        assert_eq!(0, id.apply(0));
        assert_eq!(1, id.apply(1));
        assert_eq!(1, cycle.apply(0));
        assert_eq!(2, cycle.apply(1));
        assert_eq!(0, cycle.apply(2));
        assert_eq!(3, cycle.apply(3));
    }

    #[test]
    fn mult_perm() {
        let id = Permutation::id();
        let cycle = Permutation::from_vec(vec![1, 2, 0]);
        let cycle2 = Permutation::from_vec(vec![2, 0, 1]);

        let id = &id;
        let cycle = &cycle;
        let cycle2 = &cycle2;

        assert_eq!(*id, id.multiply(id));
        assert_eq!(*cycle, cycle.multiply(id));
        assert_eq!(*cycle, id.multiply(cycle));
        assert_eq!(*cycle2, cycle.multiply(cycle));
        assert_eq!(*id, cycle.multiply(cycle).multiply(cycle));
        assert_ne!(*cycle, cycle.multiply(cycle));
        assert_eq!(*cycle, cycle.pow(1));
        assert_eq!(cycle.pow(-1), cycle.multiply(cycle));
        assert_eq!(cycle.pow(-2), *cycle);
        assert_eq!(cycle.pow(3), *id);
        assert_eq!(cycle.pow(10), *cycle);
    }
    #[test]
    fn div_perm() {
        let id = Permutation::id();
        let cycle = Permutation::from_vec(vec![1, 2, 0]);
        let cycle2 = Permutation::from_vec(vec![2, 0, 1]);

        let id = &id;
        let cycle = &cycle;
        let cycle2 = &cycle2;

        assert_eq!(*id, id.divide(id));
        assert_eq!(*cycle, cycle.divide(id));
        assert_eq!(*cycle2, id.divide(cycle));
        assert_eq!(*cycle, id.divide(cycle2));
        assert_eq!(*id, cycle.divide(cycle));
        assert_eq!(*cycle, id.divide(cycle2));
        assert_eq!(*cycle2, id.divide(cycle));
    }
}
