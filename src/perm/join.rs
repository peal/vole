use super::FullPermutation;
use super::Permutation;

#[derive(Debug, Clone)]
pub struct Join<First, Second>
where
    First: Permutation,
    Second: Permutation,
{
    first: First,
    second: Second,
}

impl<First, Second> Join<First, Second>
where
    First: Permutation,
    Second: Permutation,
{
    pub(crate) fn new(first: First, second: Second) -> Self {
        Self { first, second }
    }
}

impl<First, Second> Permutation for Join<First, Second>
where
    First: Permutation,
    Second: Permutation,
{
    fn apply(&self, x: usize) -> usize {
        self.second.apply(self.first.apply(x))
    }

    fn collapse(&self) -> FullPermutation {
        let first = self.first.collapse();
        let second = self.second.collapse();

        first.multiply(&second)
    }
}

// TODO: Here I revert to the full permutation
// Ideally I would like to have a Vec<Box<dyn Permutation>> (even tough it uses dynamic dispatching)
// to allow for true lazy "trees" all the way down. However Sized does not allow this. I think the best
// way to overcome this is via a top level enum (similar to seed::Node)

#[derive(Debug, Clone)]
pub struct MultiJoin {
    args: Vec<FullPermutation>,
}

impl MultiJoin {
    pub fn new(it: impl IntoIterator<Item = FullPermutation>) -> Self {
        MultiJoin {
            args: it.into_iter().collect(),
        }
    }
}

impl Permutation for MultiJoin {
    fn apply(&self, mut x: usize) -> usize {
        for perm in &self.args {
            x = perm.apply(x)
        }

        x
    }

    fn collapse(&self) -> FullPermutation {
        let mut res = FullPermutation::id();
        for perm in &self.args {
            res = res.multiply(&perm)
        }

        res
    }
}
