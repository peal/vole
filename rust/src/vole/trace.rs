use std::hash::{Hash, Hasher};
use std::{cmp::Ordering, collections::hash_map::DefaultHasher};

use tracing::info;

use super::backtracking::{Backtrack, Backtracking};

bitflags! {
    pub struct TracingType : u8 {
        const SYMMETRY = 0b01;
        const CANONICAL = 0b10;
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
    canonical_trace_version: usize,
}

impl Tracer {
    pub fn new_with_type(tt: TracingType) -> Self {
        Self {
            pos: Backtracking::new(0),
            tracing_type: Backtracking::new(tt),
            symmetry_trace: Default::default(),
            canonical_trace: Default::default(),
            canonical_trace_version: Default::default(),
        }
    }

    pub fn new() -> Self {
        Self::new_with_type(TracingType::BOTH)
    }

    /// Add new event to trace, returns an Err if search should backtrack
    pub fn add(&mut self, t: TraceEvent) -> Result<()> {
        if self.tracing_type.contains(TracingType::SYMMETRY) {
            if *self.pos < self.symmetry_trace.len() {
                if self.symmetry_trace[*self.pos] != t {
                    info!(target: "tracer", "Violating Symmetry Trace: found {:?}, expected {:?}", t, self.symmetry_trace[*self.pos]);
                    *self.tracing_type -= TracingType::SYMMETRY;
                } else {
                    info!(target: "tracer", "Matching trace event: {:?}, depth {:?}", t, *self.pos);
                }
            } else {
                info!(target: "tracer", "Adding trace event: {:?}, depth {:?}", t, *self.pos);
                assert!(self.symmetry_trace.len() == *self.pos);
                self.symmetry_trace.push(t);
            }
        }

        if self.tracing_type.contains(TracingType::CANONICAL) {
            if *self.pos < self.canonical_trace.len() {
                match self.canonical_trace[*self.pos].cmp(&t) {
                    Ordering::Less => {
                        info!(target: "tracer", "Found a new best minimal canonical trace");
                        self.canonical_trace.truncate(*self.pos);
                        self.canonical_trace.push(t);
                        self.canonical_trace_version += 1;
                    }
                    Ordering::Equal => {}
                    Ordering::Greater => {
                        info!(target: "tracer", "Violating canonical trace");
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
            info!(target: "tracer", "Trace fail");
            Err(TraceFailure {})
        } else {
            Ok(())
        }
    }

    /// The current type of the trace (SYMMETRY and CANONICAL) -- can change as search progresses
    pub fn tracing_type(&self) -> TracingType {
        *self.tracing_type
    }

    /// The version of the canonical trace -- this is incremented every time a new
    /// better canonical trace is found
    pub fn canonical_trace_version(&self) -> usize {
        self.canonical_trace_version
    }
}

impl Default for Tracer {
    fn default() -> Self {
        Self::new()
    }
}

impl Backtrack for Tracer {
    fn save_state(&mut self) {
        info!(target: "tracer", "Save tracer state: {:?}", *self.pos);
        self.pos.save_state();
        self.tracing_type.save_state();
    }

    fn restore_state(&mut self) {
        self.pos.restore_state();
        self.tracing_type.restore_state();
        info!(target: "tracer", "Restore tracer state: {:?}", *self.pos);
    }

    fn state_depth(&self) -> usize {
        debug_assert_eq!(self.pos.state_depth(), self.tracing_type.state_depth());
        self.pos.state_depth()
    }
}
