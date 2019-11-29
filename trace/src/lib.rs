#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub enum TraceEvent {
    Start(),
    End(),
    Split{cell: usize, size: usize, reasons:usize},
    NoSplit{cell:usize, reason:usize}
}

pub struct TraceFailure {}

trait Tracer {
    fn add(&mut self, t: TraceEvent) -> Result<(),TraceFailure>;
}

pub struct RecordingTracer {
    trace: Vec<TraceEvent>
}

impl RecordingTracer {
    fn new() -> RecordingTracer {
        RecordingTracer{ trace: vec![] }
    }
}

impl Tracer for RecordingTracer {
    fn add(&mut self, t: TraceEvent) -> Result<(),TraceFailure>
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
    fn new(trace: Vec<TraceEvent>) -> ReplayingTracer {
        ReplayingTracer{trace, pos: 0}
    }
}

impl Tracer for ReplayingTracer {
    fn add(&mut self, t: TraceEvent) -> Result<(),TraceFailure>
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
