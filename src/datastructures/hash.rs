use std::hash::{Hash, Hasher};
use twox_hash::XxHash64;

pub fn do_hash<T>(obj: T) -> usize
where
    T: Hash,
{
    let mut hasher = XxHash64::default();
    obj.hash(&mut hasher);
    hasher.finish() as usize
}
