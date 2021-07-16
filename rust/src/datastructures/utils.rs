use std::collections::HashMap;

pub fn to_vec_vec(uf: &disjoint_sets::UnionFind<usize>) -> Vec<Vec<usize>> {
    let mut h: HashMap<usize, Vec<usize>> = HashMap::new();

    for i in 0..uf.len() {
        let m = uf.find(i);
        let elms = h.entry(m).or_insert_with(|| -> Vec<usize> {vec![]});
        elms.push(i);
    }

    let mut orbs: Vec<Vec<usize>> = h.into_iter().map(|(_, v)| v).collect();

    for o in &mut orbs {
        o.sort();
    }
    orbs.sort();
    orbs
}

#[cfg(test)]
mod tests {
    use crate::datastructures::utils::to_vec_vec;
    #[test]
    fn basic_test() {
        let mut s: disjoint_sets::UnionFind<usize> = disjoint_sets::UnionFind::new(5);
        assert_eq!(
            to_vec_vec(&s),
            vec![vec![0], vec![1], vec![2], vec![3], vec![4]]
        );
        s.union(1, 3);
        assert_eq!(to_vec_vec(&s), vec![vec![0], vec![1, 3], vec![2], vec![4]]);
        s.union(2, 4);
        assert_eq!(to_vec_vec(&s), vec![vec![0], vec![1, 3], vec![2, 4]]);
        s.union(4, 0);
        assert_eq!(to_vec_vec(&s), vec![vec![0, 2, 4], vec![1, 3]]);
        s.union(1, 0);
        assert_eq!(to_vec_vec(&s), vec![vec![0, 1, 2, 3, 4]]);
    }
}
