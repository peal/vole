use super::{FullPermutation, Permutation};
use std::collections::hash_map::Entry;
use std::collections::HashMap;

pub struct SchreierVector {
    base: usize,
    transversal: HashMap<usize, FullPermutation>,
}

impl SchreierVector {
    pub fn from_generators(base: usize, gens: Vec<FullPermutation>) -> SchreierVector {
        let mut transversal = HashMap::new();
        transversal.insert(base, FullPermutation::id());

        let mut q = std::collections::VecDeque::new();
        q.push_back(base);

        while !q.is_empty() {
            let val = q.pop_front().unwrap();
            for g in &gens {
                let img = g.apply(val);
                if let Entry::Vacant(v) = transversal.entry(img) {
                    v.insert(g.inv());
                    q.push_back(img);
                }
            }
        }

        SchreierVector { base, transversal }
    }

    pub fn base(&self) -> usize {
        self.base
    }

    pub fn in_orbit(&self, pos: usize) -> bool {
        self.transversal.contains_key(&pos)
    }
}

pub struct StabiliserChain {
    svector: SchreierVector,
    stabilizer: Option<Box<StabiliserChain>>,
}

impl StabiliserChain {
    pub fn base(&self) -> usize {
        self.svector.base
    }

    pub fn transveral(&self) -> &SchreierVector {
        &self.svector
    }

    pub fn stabilizer(&self) -> &Option<Box<StabiliserChain>> {
        &self.stabilizer
    }
}

#[cfg(test)]
mod tests {
    use super::SchreierVector;
    use crate::perm::FullPermutation;

    #[test]
    fn id_stabchain() {
        let sc = SchreierVector::from_generators(2, vec![]);
        assert_eq!(sc.base(), 2);
        assert!(sc.in_orbit(2));
        assert!(!sc.in_orbit(1));
        assert!(!sc.in_orbit(3));
    }

    #[test]
    fn simple_stabchain() {
        let sc =
            SchreierVector::from_generators(1, vec![FullPermutation::from_vec(vec![0, 3, 2, 1])]);
        assert_eq!(sc.base(), 1);
        assert!(sc.in_orbit(1));
        assert!(sc.in_orbit(3));
        assert!(!sc.in_orbit(0));
        assert!(!sc.in_orbit(2));
    }
}
