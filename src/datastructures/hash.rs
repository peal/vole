//! Hashing

use std::{
    hash::{Hash, Hasher},
    num::Wrapping,
};

/// A simple helper to hash any object
pub fn do_hash<T>(obj: T) -> Wrapping<usize>
where
    T: Hash,
{
    let mut hasher = seahash::SeaHasher::default();
    obj.hash(&mut hasher);
    Wrapping(hasher.finish() as usize)
}
