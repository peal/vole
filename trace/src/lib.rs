use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};


#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub enum TraceEvent {
    Start(),
    End(),
    Split{cell: usize, size: usize, reason:u64},
    NoSplit{cell:usize, reason:u64}
}

pub fn hash<T: Hash>(t: &T) -> u64 {
    let mut s = DefaultHasher::new();
    t.hash(&mut s);
    s.finish()
}

#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub struct TraceFailure {}

pub type Result<T> = std::result::Result<T, TraceFailure>;

pub trait Tracer {
    fn add(&mut self, t: TraceEvent) -> Result<()>;
}

#[derive(Clone, Debug, Default)]
pub struct RecordingTracer {
    trace: Vec<TraceEvent>
}

impl RecordingTracer {
    pub fn new() -> Self {
        Default::default()
    }
}

impl Tracer for RecordingTracer {
    fn add(&mut self, t: TraceEvent) -> Result<()>
    {
        self.trace.push(t);
        Ok(())
    }
}

pub struct ReplayingTracer {
    trace: Vec<TraceEvent>,
    pos: usize
}

impl ReplayingTracer {
    pub fn new(trace: Vec<TraceEvent>) -> ReplayingTracer {
        ReplayingTracer{trace, pos: 0}
    }
}

impl Tracer for ReplayingTracer {
    fn add(&mut self, t: TraceEvent) -> Result<()>
    {
        if self.pos >= self.trace.len() {
            Err(TraceFailure{})
        } else if t != self.trace[self.pos] {
            Err(TraceFailure{})
        } else {
            self.pos += 1;
            Ok(())
        }
    }
}


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
