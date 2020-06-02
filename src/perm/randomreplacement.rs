use super::Permutation;
use rand::Rng;

/// Generate random elements of a group using Random Replacement
#[derive(Clone, Debug)]
pub struct RandomReplacement<P: Permutation> {
    list: Vec<P>,
}

impl<P: Permutation> RandomReplacement<P> {
    /// Initialise random replacement
    pub fn from_generators(gens: Vec<P>) -> RandomReplacement<P> {
        let mut list = gens;
        // Make list at least length 10
        while list.len() < 10 {
            list.push(list[0].clone());
        }
        RandomReplacement { list }
    }

    pub fn gen<R: Rng>(&mut self, rng: &mut R) -> P {
        let i = rng.gen_range(0, self.list.len());
        let mut j = rng.gen_range(0, self.list.len());
        while i == j {
            j = rng.gen_range(0, self.list.len());
        }
        if rng.gen() {
            self.list[i] = self.list[i].and_then(&self.list[j]).collapse();
        } else {
            self.list[i] = self.list[i].divide(&self.list[j]).collapse();
        }
        return self.list[i].clone();
    }
}

#[cfg(test)]
mod tests {
    use super::RandomReplacement;
    use crate::perm::Permutation;
    use rand::SeedableRng;
    use rand_chacha::ChaCha8Rng;
    use std::collections::HashMap;

    #[test]
    fn basic() {
        let mut replace = RandomReplacement::from_generators(vec![
            Permutation::from_vec(vec![3, 0, 1, 2]),
            Permutation::from_vec(vec![1, 0]),
        ]);
        let mut gen = ChaCha8Rng::from_seed([1; 32]);
        let mut count = HashMap::new();
        // This should be enough to make all the group, and as we fix the seed this test
        // should not randomly fail
        let loopsize = 1000;
        for i in 0..loopsize {
            let made = replace.gen(&mut gen);
            *count.entry(made).or_insert(0) += 1;
        }
        let len = count.len();
        assert_eq!(len, 24);
        // Check we made a "reasonable" number of each element
        for (_, n) in count {
            assert!(n > loopsize / 2 / len);
            assert!(n < loopsize * 2 / len);
        }
    }
}
