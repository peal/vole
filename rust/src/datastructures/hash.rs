//! Hashing

use std::{
    hash::{Hash, Hasher},
    num::Wrapping,
};

pub trait QuickHashable {
    fn quick_hash(&self) -> Wrapping<usize>;
}

impl<T: QuickHashable + Copy> QuickHashable for &T {
    fn quick_hash(&self) -> Wrapping<usize> {
        (*self).quick_hash()
    }
}

impl QuickHashable for usize {
    fn quick_hash(&self) -> Wrapping<usize> {
        let hash = seahash::hash(&self.to_le_bytes()) as usize;
        Wrapping(hash)
    }
}

impl QuickHashable for isize {
    fn quick_hash(&self) -> Wrapping<usize> {
        let hash = seahash::hash(&self.to_le_bytes()) as usize;
        Wrapping(hash)
    }
}

impl QuickHashable for Wrapping<usize> {
    fn quick_hash(&self) -> Wrapping<usize> {
        let hash = seahash::hash(&self.0.to_le_bytes()) as usize;
        Wrapping(hash)
    }
}

impl QuickHashable for bool {
    fn quick_hash(&self) -> Wrapping<usize> {
        Wrapping(if *self { 123456789 } else { 987654321 })
    }
}

impl QuickHashable for (usize, Wrapping<usize>) {
    fn quick_hash(&self) -> Wrapping<usize> {
        let (a, b) = &self;
        let hasha = seahash::hash(&a.to_le_bytes()) as usize;
        let hashb = seahash::hash(&b.0.to_le_bytes()) as usize;
        Wrapping(hasha * hashb)
    }
}

impl QuickHashable for (Wrapping<usize>, usize) {
    fn quick_hash(&self) -> Wrapping<usize> {
        let (a, b) = &self;
        let hasha = seahash::hash(&a.0.to_le_bytes()) as usize;
        let hashb = seahash::hash(&b.to_le_bytes()) as usize;
        Wrapping(hasha * hashb)
    }
}

/// A simple helper to hash any object
pub fn do_hash<T>(obj: T) -> Wrapping<usize>
where
    T: Hash,
{
    let mut hasher = seahash::SeaHasher::default();
    obj.hash(&mut hasher);
    Wrapping(hasher.finish() as usize)
}
