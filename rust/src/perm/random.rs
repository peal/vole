use rand::{thread_rng, Rng};

use super::Permutation;

pub struct RandomPerm {
    state: Vec<Permutation>,
}

impl RandomPerm {
    pub fn new(invec: Vec<Permutation>) -> Self {
        assert!(!invec.is_empty());
        let mut v = invec;
        let mut offset = 0;
        while v.len() < 10 {
            let p = v[offset].clone();
            offset += 1;
            v.push(p);
        }

        Self { state: v }
    }

    pub fn randperm(&mut self) -> Permutation {
        let mut rng = thread_rng();
        let i = rng.gen_range(0..self.state.len());
        let mut j = rng.gen_range(0..self.state.len());
        while i == j {
            j = rng.gen_range(0..self.state.len());
        }
        let flip: bool = rng.gen();
        let newperm = if flip {
            self.state[i].multiply(&self.state[j])
        } else {
            self.state[i].multiply(&self.state[j].inv())
        };
        self.state[i] = newperm.clone();
        newperm
    }
}

#[cfg(test)]
mod tests {
    use std::collections::HashSet;

    use super::RandomPerm;
    use crate::perm::Permutation;

    #[test]
    fn make_trivial() {
        let p = Permutation::id();
        let mut r = RandomPerm::new(vec![p]);
        let mut v = vec![];
        for _ in 1..100000 {
            v.push(r.randperm());
        }
        let h: HashSet<Permutation> = v.into_iter().collect();
        assert!(h.len() == 1);
    }

    #[test]
    fn make_lots() {
        let p = Permutation::from_vec(vec![6, 0, 1, 2, 3, 4, 5]);
        let q = Permutation::from_vec(vec![1, 0]);
        let mut r = RandomPerm::new(vec![p, q]);
        let mut v = vec![];
        for _ in 1..100000 {
            v.push(r.randperm());
        }
        let h: HashSet<Permutation> = v.into_iter().collect();
        assert!(h.len() == 7 * 6 * 5 * 4 * 3 * 2);
    }
}
