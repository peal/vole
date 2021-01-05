use std::{
    hash::{Hash, Hasher},
    num::Wrapping,
};
use twox_hash::XxHash64;

pub fn do_hash<T>(obj: T) -> Wrapping<usize>
where
    T: Hash,
{
    let mut hasher = XxHash64::default();
    obj.hash(&mut hasher);
    Wrapping(hasher.finish() as usize)
}
