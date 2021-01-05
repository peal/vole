use smallbitvec::SmallBitVec;

#[derive(Debug, Clone)]
pub struct SmallIntSet {
    bit_set: SmallBitVec,
    values: Vec<usize>,
}

impl SmallIntSet {
    pub fn with_size(size: usize) -> Self {
        Self {
            bit_set: SmallBitVec::from_elem(size, false),
            values: vec![],
        }
    }

    pub fn contains(&self, size: usize) -> bool {
        self.bit_set[size]
    }

    pub fn add(&mut self, pos: usize) {
        if !self.bit_set.get(pos).unwrap() {
            self.bit_set.set(pos, true);
            self.values.push(pos)
        }
    }

    pub fn iter(&self) -> ::std::slice::Iter<usize> {
        self.values.iter()
    }
}

#[cfg(test)]
mod tests {
    use super::SmallIntSet;

    #[test]
    fn basic_test() {
        let mut set = SmallIntSet::with_size(5);
        assert!(!set.contains(3));
        assert!(!set.contains(0));
        set.add(2);
        assert!(set.contains(2));
        assert!(!set.contains(3));
        assert_eq!(set.iter().cloned().collect::<Vec<_>>(), vec![2]);
        set.add(2);
        assert_eq!(set.iter().cloned().collect::<Vec<_>>(), vec![2]);
        set.add(0);
        set.add(3);
        assert_eq!(set.iter().cloned().collect::<Vec<_>>(), vec![2, 0, 3]);
        set.add(4);
        assert_eq!(set.iter().cloned().collect::<Vec<_>>(), vec![2, 0, 3, 4]);
    }
}
