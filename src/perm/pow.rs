use super::join::MultiJoin;
use super::FullPermutation;
use super::Permutation;

#[derive(Debug, Clone)]
pub struct Pow<Perm>
where
    Perm: Permutation,
{
    perm: Perm,
    power: isize,
}

impl<Perm> Pow<Perm>
where
    Perm: Permutation,
{
    pub(crate) fn new(perm: Perm, power: isize) -> Self {
        Pow { perm, power }
    }

    // TODO: This is not really the conjugate I just wanted a nice name
    fn conj(&self) -> Pow<FullPermutation> {
        Pow::new(self.perm.inv(), self.power.abs())
    }
}

impl<Perm> Permutation for Pow<Perm>
where
    Perm: Permutation,
{
    fn apply(&self, mut x: usize) -> usize {
        if self.power < 0 {
            return self.conj().apply(x);
        }

        for _ in 0..self.power {
            x = self.perm.apply(x)
        }

        x
    }

    fn collapse(&self) -> FullPermutation {
        if self.power < 0 {
            return self.conj().collapse();
        }

        MultiJoin::new(
            std::iter::repeat(self.perm.clone())
                .take(self.power.abs() as usize)
                .map(|p| p.collapse()),
        )
        .collapse()
    }
}
