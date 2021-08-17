use std::collections::HashMap;

use crate::perm::Permutation;

/// A union-find with an extra value 'depth_explored', which is stored per union. When two
/// unions are combined, they take the smallest 'depth_explored' value of their components.
#[derive(Debug)]
pub struct UnionFind {
    orbit_mins: Vec<usize>,
    depth_explored: Vec<usize>,
}

impl UnionFind {
    pub fn new(size: usize) -> Self {
        Self {
            orbit_mins: vec![usize::max_value(); size],
            depth_explored: vec![usize::max_value(); size],
        }
    }

    pub fn expand_to(&mut self, size: usize) {
        while self.orbit_mins.len() < size {
            self.orbit_mins.push(usize::max_value());
            self.depth_explored.push(usize::max_value());
        }
    }

    pub fn len(&self) -> usize {
        self.orbit_mins.len()
    }

    pub fn is_empty(&self) -> bool {
        self.orbit_mins.is_empty()
    }

    pub fn find(&self, mut p: usize) -> usize {
        while self.orbit_mins[p] != usize::max_value() {
            p = self.orbit_mins[p];
        }
        p
    }

    pub fn depth_explored(&self, p: usize) -> usize {
        let find_p = self.find(p);
        self.depth_explored[find_p]
    }

    pub fn set_depth_explored(&mut self, p: usize, depth: usize) {
        let find_p = self.find(p);
        assert!(self.depth_explored[find_p] > depth);
        self.depth_explored[find_p] = depth;
    }

    pub fn union(&mut self, a: usize, b: usize) -> bool {
        if a == b {
            return false;
        }
        let af = self.find(a);
        let bf = self.find(b);
        if af == bf {
            return false;
        }

        let min_depth_explored = std::cmp::min(self.depth_explored[af], self.depth_explored[bf]);

        let base = if af < bf { af } else { bf };

        self.orbit_mins[af] = base;
        self.orbit_mins[bf] = base;
        self.orbit_mins[a] = base;
        self.orbit_mins[b] = base;
        self.orbit_mins[base] = usize::max_value();
        self.depth_explored[base] = min_depth_explored;
        true
    }

    pub fn union_permutation(&mut self, p: &Permutation) {
        let max_p = p.lmp().unwrap_or(0) + 1;

        for i in 0..max_p {
            self.union(i, p.apply(i));
        }
    }

    /// Should we branch on this value at this depth
    pub fn orbit_needs_searching(&mut self, c: usize, depth: usize) -> bool {
        if self.orbit_mins[c] != usize::max_value() {
            return false;
        }

        assert!(self.depth_explored[c] >= depth);
        self.depth_explored[c] > depth
    }

    /// Mark we have searched this point
    pub fn set_orbit_searched(&mut self, c: usize, depth: usize) {
        let c_f = self.find(c);
        assert!(self.depth_explored[c_f] >= depth);
        self.depth_explored[c_f] = depth;
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
        assert_eq!(s.to_vec_vec(), vec![vec![0], vec![1], vec![2], vec![3], vec![4]]);
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
