use std::iter::FromIterator;

use serde::{Deserialize, Serialize};

/// A vector which is always sorted.
#[derive(Debug, Clone, Eq, Ord, PartialEq, PartialOrd, Serialize, Deserialize, Hash)]
pub struct SortedVec<T: Ord> {
    vec: Vec<T>,
}

impl<T: Ord> SortedVec<T> {
    /// Creates a new sorted vector
    pub fn from_unsorted(mut vec: Vec<T>) -> Self {
        vec.sort_unstable();
        Self { vec }
    }

    /// Checks if vector contains `val`
    pub fn contains(&self, val: &T) -> bool {
        self.vec.binary_search(val).is_ok()
    }

    /// Length of vector
    pub fn len(&self) -> usize {
        self.vec.len()
    }

    /// Returns if vector is empty
    pub fn is_empty(&self) -> bool {
        self.vec.is_empty()
    }

    /// Returns an iterator over the vector
    pub fn iter(&self) -> std::slice::Iter<T> {
        self.into_iter()
    }
}

impl<T: Ord> FromIterator<T> for SortedVec<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> Self {
        let mut c: Vec<T> = Vec::new();

        for i in iter {
            c.push(i);
        }
        Self::from_unsorted(c)
    }
}

impl<T: Ord> IntoIterator for SortedVec<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.vec.into_iter()
    }
}

impl<'s, T: Ord> IntoIterator for &'s SortedVec<T> {
    type Item = &'s T;
    type IntoIter = std::slice::Iter<'s, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.vec.iter()
    }
}

#[cfg(test)]
mod tests {
    use super::SortedVec;

    #[test]
    fn basic_test() {
        let s = SortedVec::from_unsorted(vec![2, 5, 4]);
        assert!(s.len() == 3);
        assert!(s.contains(&2));
        assert!(s.contains(&4));
        assert!(s.contains(&5));
        assert!(!s.contains(&1));
        assert!(!s.contains(&3));
        assert!(!s.contains(&6));

        let t: SortedVec<i32> = vec![4, 3, 1].iter().map(|&x| x + 1).collect();
        assert_eq!(t, s);

        let w: SortedVec<i32> = t.into_iter().map(|x| x * 2).collect();
        assert_eq!(w, SortedVec::from_unsorted(vec![10, 4, 8]));
    }
}
