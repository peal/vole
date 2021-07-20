use std::collections::HashMap;

#[derive(Debug)]
pub struct UnionFind {
    orbit_mins: Vec<usize>,
}

impl UnionFind {
    pub fn new(size: usize) -> Self {
        Self {
            orbit_mins: vec![usize::MAX; size],
        }
    }

    pub fn expand_to(&mut self, size: usize) {
        while self.orbit_mins.len() < size {
            self.orbit_mins.push(usize::MAX);
        }
    }

    pub fn len(&self) -> usize {
        self.orbit_mins.len()
    }

    pub fn find(&self, mut p: usize) -> usize {
        while self.orbit_mins[p] != usize::MAX {
            p = self.orbit_mins[p];
        }
        p
    }

    pub fn union(&mut self, a: usize, b: usize) -> bool {
        let af = self.find(a);
        let bf = self.find(b);
        if af == bf {
            return false;
        }

        let base = if af < bf { af } else { bf };

        self.orbit_mins[af] = base;
        self.orbit_mins[bf] = base;
        self.orbit_mins[a] = base;
        self.orbit_mins[b] = base;
        self.orbit_mins[base] = usize::MAX;
        true
    }

    pub fn to_vec_vec(&self) -> Vec<Vec<usize>> {
        let mut h: HashMap<usize, Vec<usize>> = HashMap::new();

        for i in 0..self.len() {
            let m = self.find(i);
            let elms = h.entry(m).or_insert_with(|| -> Vec<usize> { vec![] });
            elms.push(i);
        }

        let mut orbs: Vec<Vec<usize>> = h.into_iter().map(|(_, v)| v).collect();

        for o in &mut orbs {
            o.sort();
        }
        orbs.sort();
        orbs
    }
}

#[cfg(test)]
mod tests {
    use crate::datastructures::unionfind::UnionFind;

    #[test]
    fn basic_test() {
        let mut s: UnionFind = UnionFind::new(5);
        assert_eq!(
            s.to_vec_vec(),
            vec![vec![0], vec![1], vec![2], vec![3], vec![4]]
        );
        s.union(1, 3);
        assert_eq!(s.to_vec_vec(), vec![vec![0], vec![1, 3], vec![2], vec![4]]);
        s.union(2, 4);
        assert_eq!(s.to_vec_vec(), vec![vec![0], vec![1, 3], vec![2, 4]]);
        s.union(4, 0);
        assert_eq!(s.to_vec_vec(), vec![vec![0, 2, 4], vec![1, 3]]);
        s.union(1, 0);
        assert_eq!(s.to_vec_vec(), vec![vec![0, 1, 2, 3, 4]]);
    }
}
