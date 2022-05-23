//! A set of integers with O(1) lookup and O(1) iteration through members.

/// A set of integers with O(1) lookup and iteration
#[derive(Debug, Clone)]
pub struct SmallIntSet {
    bit_set: Vec<bool>,
    values: Vec<usize>,
}

impl SmallIntSet {
    /// Create empty set with size `usize`
    pub fn new(size: usize) -> Self {
        Self {
            bit_set: vec![false; size],
            values: vec![],
        }
    }

    /// Check if set contains `i`
    fn contains(&self, i: usize) -> bool {
        self.bit_set[i]
    }

    /// Insert `i` into set (does nothing if `i` is already in the set)
    pub fn insert(&mut self, i: usize) {
        if !self.bit_set[i] {
            self.bit_set[i] = true;
            self.values.push(i)
        }
    }

    /// Return an iterator to iterate through the set (in sorted order)
    pub fn sorted_iter(&mut self) -> ::std::slice::Iter<usize> {
        // Sort lazily
        self.values.sort();
        self.values.iter()
    }

    /// Remove all elements from the set
    fn clear(&mut self) {
        for i in self.values.iter() {
            self.bit_set[*i] = false;
        }
        self.values.clear();
        assert!(self.values.is_empty());
    }

    /// Check if set is empty
    fn is_empty(&self) -> bool {
        self.values.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::SmallIntSet;

    #[test]
    fn basic_test() {
        let mut set = SmallIntSet::new(5);
        assert!(!set.contains(3));
        assert!(!set.contains(0));
        set.insert(2);
        assert!(set.contains(2));
        assert!(!set.contains(3));
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<_>>(), vec![2]);
        set.insert(2);
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<_>>(), vec![2]);
        set.insert(0);
        set.insert(3);
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<_>>(), vec![0, 2, 3]);
        set.insert(4);
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<_>>(), vec![0, 2, 3, 4]);
        set.clear();
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<usize>>(), Vec::<usize>::new());
        assert!(!set.contains(3));
        assert!(!set.contains(0));
        assert!(!set.contains(2));
        set.insert(2);
        assert!(set.contains(2));
        assert!(!set.contains(3));
        assert_eq!(set.sorted_iter().cloned().collect::<Vec<_>>(), vec![2]);
    }
}
