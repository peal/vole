use std::cmp::max;
use std::rc::Rc;

#[derive(Clone, Debug, Eq)]
pub struct Permutation {
    vals: Rc<Vec<usize>>,
}

impl Permutation {
    pub fn id() -> Permutation {
        Permutation {
            vals: Rc::new(Vec::new()),
        }
    }

    pub fn from_vec(mut vals: Vec<usize>) -> Permutation {
        while !vals.is_empty() && vals[vals.len() - 1] == vals.len() - 1 {
            vals.pop();
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

impl std::cmp::PartialEq for Permutation {
    fn eq(&self, other: &Permutation) -> bool {
        self.vals == other.vals
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
            let mut v = vec![0; size + 1];
            for i in 0..=size {
                v[i] = (i ^ self) ^ other;
            }
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
        assert_eq!(id, &id * &id);
        assert_eq!(cycle, &cycle * &id);
        assert_eq!(cycle, &id * &cycle);
        assert_eq!(id, &cycle * &cycle * &cycle);
        assert_ne!(cycle, &cycle * &cycle);
        assert_eq!(cycle, (&cycle) ^ 1);
        assert_eq!((&cycle) ^ (-1), &cycle * &cycle);
        assert_eq!((&cycle) ^ (-2), cycle);
        assert_eq!((&cycle) ^ 3, id);
        assert_eq!((&cycle) ^ 10, cycle);
    }
}
