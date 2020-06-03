//! Digraphs
//!
//! This crate implements permutations on integers

// mod randomreplacement;
mod full_permutation;
mod join;
mod pow;
mod schreiervector;

pub use full_permutation::FullPermutation;
use join::Join;
use pow::Pow;

pub trait Permutation: Clone {
    /// Builds from a Vec
    fn from_vec(vals: Vec<usize>) -> Self;
    // {
    //    FullPermutation::from_vec(vals)
    //}

    /// Computes f(x)
    fn apply(&self, x: usize) -> usize;

    /// TODO: What is more efficient (a * b)^-1 or (b^-1 * a^-1)? If the latter join can benefit from a
    /// ad hominem implementation
    fn inv(&self) -> Self;

    /// Computes g^x
    fn pow(&self, x: isize) -> Self {
        if x == 0 {
            Self::from_vec(vec![])
        } else if x < 0 {
            self.inv().pow(-x)
        } else {
            let mut p = self.clone();
            for i in 1..x {
                p = p.multiply(self)
            }
            p
        }
    }

    /// Computes g / f = g * f^-1. Note that here an alternative is to compute .inv() directly but since
    /// Most others operations are lazy I prefer this approach a bit.
    fn divide<InPerm: Permutation>(&self, other: &InPerm) -> Self {
        self.multiply(&other.inv())
    }

    /// Very general type that allows to join permutations depending on how efficient we want them
    fn multiply<InPerm: Permutation>(&self, next: &InPerm) -> Self;

    // Find the largest point moved by the permutation (returns None for the identity permutation)
    fn lmp(&self) -> Option<usize>;

    fn is_id(&self) -> bool {
        self.lmp().is_none()
    }
}

pub trait PermBuilder: Clone {
    /// Builds from a Vec
    fn lazy_from_vec(vals: Vec<usize>) -> FullPermutation {
        FullPermutation::from_vec(vals)
    }

    /// Computes f(x)
    fn build_apply(&self, x: usize) -> usize;

    /// TODO: What is more efficient (a * b)^-1 or (b^-1 * a^-1)? If the latter join can benefit from a
    /// ad hominem implementation
    fn build_inv(&self) -> FullPermutation {
        self.collapse().inv()
    }

    /// Computes g^x
    fn build_pow(&self, x: isize) -> Pow<Self> {
        Pow::new(self.clone(), x)
    }

    /// Computes g / f = g * f^-1. Note that here an alternative is to compute .inv() directly but since
    /// Most others operations are lazy I prefer this approach a bit.
    fn build_divide<InPerm: PermBuilder>(&self, other: &InPerm) -> Join<Self, Pow<InPerm>> {
        Join::new(self.clone(), Pow::new(other.clone(), -1))
    }

    /// Very general type that allows to join permutations depending on how efficient we want them
    fn build_multiply<InPerm: PermBuilder>(&self, next: &InPerm) -> Join<Self, InPerm> {
        Join::new(self.clone(), next.clone())
    }

    /// Unfold all the layers and make a single permutation (Note, often it will be wanted to store this)
    fn collapse(&self) -> FullPermutation;
}
