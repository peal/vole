use std::hash::{Hash, Hasher};
use std::{cmp::Ordering, collections::hash_map::DefaultHasher};

use tracing::info;

use super::backtracking::{Backtrack, Backtracking};

bitflags! {
    pub struct TracingType : u8 {
        const SYMMETRY = 0b01;
        const CANONICAL = 0b1;
        const BOTH = 0b11;
        const NONE = 0b00;
    }
}

#[derive(Copy, Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
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

#[derive(Debug)]
pub struct Tracer {
    pos: Backtracking<usize>,
    tracing_type: Backtracking<TracingType>,
    symmetry_trace: Vec<TraceEvent>,
    canonical_trace: Vec<TraceEvent>,
}

impl Tracer {
    pub fn new_with_type(tt: TracingType) -> Self {
        Self {
            pos: Backtracking::new(0),
            tracing_type: Backtracking::new(tt),
            symmetry_trace: Default::default(),
            canonical_trace: Default::default(),
        }
    }

    pub fn new() -> Self {
        Self::new_with_type(TracingType::BOTH)
    }

    pub fn add(&mut self, t: TraceEvent) -> Result<()> {
        if self.tracing_type.contains(TracingType::SYMMETRY) {
            if *self.pos < self.symmetry_trace.len() {
                if self.symmetry_trace[*self.pos] != t {
                    info!("Violating Symmetry Trace");
                    *self.tracing_type -= TracingType::SYMMETRY;
                }
            } else {
                assert!(self.symmetry_trace.len() == *self.pos);
                self.symmetry_trace.push(t);
            }
        }

        if self.tracing_type.contains(TracingType::CANONICAL) {
            if *self.pos < self.canonical_trace.len() {
                match self.canonical_trace[*self.pos].cmp(&t) {
                    Ordering::Less => {
                        info!("Found a new best minimal canonical trace");
                        self.canonical_trace.truncate(*self.pos);
                        self.canonical_trace.push(t);
                    }
                    Ordering::Equal => {}
                    Ordering::Greater => {
                        info!("Violating canonical trace");
                        *self.tracing_type -= TracingType::CANONICAL;
                    }
                }
            } else {
                assert!(self.canonical_trace.len() == *self.pos);
                self.canonical_trace.push(t);
            }
        }

        *self.pos += 1;

        if *self.tracing_type == TracingType::NONE {
            info!("Trace fail");
            Err(TraceFailure {})
        } else {
            Ok(())
        }
    }

    pub fn tracing_type(&self) -> TracingType {
        *self.tracing_type
    }
}

impl Default for Tracer {
    fn default() -> Self {
        Self::new()
    }
}

impl Backtrack for Tracer {
    fn save_state(&mut self) {
        self.pos.save_state();
        self.tracing_type.save_state();
    }

    fn restore_state(&mut self) {
        self.pos.restore_state();
        self.tracing_type.restore_state();
    }
}
