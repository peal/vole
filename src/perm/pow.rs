use super::join::MultiJoin;
use super::FullPermutation;
use super::PermBuilder;

#[derive(Debug, Clone)]
pub struct Pow<Perm>
where
    Perm: PermBuilder,
{
    perm: Perm,
    power: isize,
}

impl<Perm> Pow<Perm>
where
    Perm: PermBuilder,
{
    pub(crate) fn new(perm: Perm, power: isize) -> Self {
        Pow { perm, power }
    }

    // TODO: This is not really the conjugate I just wanted a nice name
    fn conj(&self) -> Pow<FullPermutation> {
        Pow::new(self.perm.build_inv(), self.power.abs())
    }
}

impl<Perm> PermBuilder for Pow<Perm>
where
    Perm: PermBuilder,
{
    fn build_apply(&self, mut x: usize) -> usize {
        if self.power < 0 {
            return self.conj().build_apply(x);
        }

        for _ in 0..self.power {
            x = self.perm.build_apply(x)
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
