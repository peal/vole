use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub enum TraceEvent {
    Start(),
    End(),
    Split {
        cell: usize,
        size: usize,
        reason: u64,
    },
    NoSplit {
        cell: usize,
        reason: u64,
    },
}

pub fn hash<T: Hash>(t: &T) -> u64 {
    let mut s = DefaultHasher::new();
    t.hash(&mut s);
    s.finish()
}

#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub struct TraceFailure {}

pub type Result<T> = std::result::Result<T, TraceFailure>;

#[derive(Clone, Debug)]
pub struct Tracer {
    recording: bool,
    pos: usize,
    trace: Vec<TraceEvent>,
}

impl Tracer {
    pub fn new() -> Self {
        Self {
            recording: true,
            pos: 0,
            trace: Default::default(),
        }
    }

    pub fn add(&mut self, t: TraceEvent) -> Result<()> {
        if self.recording {
            self.trace.push(t);
            return Ok(());
        }

        if self.pos >= self.trace.len() || self.trace[self.pos] != t {
            return Err(TraceFailure {});
        }

        self.pos += 1;
        Ok(())
    }
}

impl Default for Tracer {
    fn default() -> Self {
        Self::new()
    }
}
