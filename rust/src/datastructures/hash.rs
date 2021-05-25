//! Hashing

use std::{
    hash::{Hash, Hasher},
    num::Wrapping,
};

pub type QHash = u64;

pub trait QuickHashable {
    fn quick_hash(&self) -> Wrapping<QHash>;
}

impl<T: QuickHashable + Copy> QuickHashable for &T {
    fn quick_hash(&self) -> Wrapping<QHash> {
        (*self).quick_hash()
    }
}

impl QuickHashable for usize {
    fn quick_hash(&self) -> Wrapping<QHash> {
        let hash = seahash::hash(&self.to_le_bytes()) as QHash;
        Wrapping(hash)
    }
}

impl QuickHashable for isize {
    fn quick_hash(&self) -> Wrapping<QHash> {
        let hash = seahash::hash(&self.to_le_bytes()) as QHash;
        Wrapping(hash)
    }
}

impl QuickHashable for Wrapping<QHash> {
    fn quick_hash(&self) -> Wrapping<QHash> {
        let hash = seahash::hash(&self.0.to_le_bytes()) as QHash;
        Wrapping(hash)
    }
}

impl QuickHashable for bool {
    fn quick_hash(&self) -> Wrapping<QHash> {
        Wrapping(if *self { 123456789 } else { 987654321 })
    }
}

impl QuickHashable for (usize, Wrapping<QHash>) {
    fn quick_hash(&self) -> Wrapping<QHash> {
        let (a, b) = &self;
        let hasha = seahash::hash(&a.to_le_bytes()) as QHash;
        let hashb = seahash::hash(&b.0.to_le_bytes()) as QHash;
        Wrapping(hasha * hashb)
    }
}

impl QuickHashable for (Wrapping<QHash>, usize) {
    fn quick_hash(&self) -> Wrapping<QHash> {
        let (a, b) = &self;
        let hasha = seahash::hash(&a.0.to_le_bytes()) as QHash;
        let hashb = seahash::hash(&b.to_le_bytes()) as QHash;
        Wrapping(hasha * hashb)
    }
}

/// A simple helper to hash any object
pub fn do_hash<T>(obj: T) -> Wrapping<QHash>
where
    T: Hash,
{
    let mut hasher = seahash::SeaHasher::default();
    obj.hash(&mut hasher);
    Wrapping(hasher.finish() as QHash)
}
