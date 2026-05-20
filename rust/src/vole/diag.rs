//! Search-time diagnostic dump for Vole's partition state.
//!
//! This module produces a stream of human-readable lines describing
//! what the search is doing: the partition shape after each
//! refinement, the cell and value chosen at each branching node, and
//! whatever trace events the engine emits along the way.  Output goes
//! to stderr.
//!
//! Gated by the `VOLE_DUMP` environment variable (parsed once at
//! first access; zero cost when unset):
//!
//!   VOLE_DUMP=partition   — emit `init` / `refine` events with the
//!                           full partition shape.
//!   VOLE_DUMP=branch      — also emit `branch` events with the
//!                           cell and value chosen.
//!   VOLE_DUMP=trace       — also emit raw trace events (Split,
//!                           NoSplit, EndRefine, …) from the tracer.
//!   VOLE_DUMP=full        — everything above.
//!   (unset)               — silent.
//!
//! Lines look like:
//!
//!   [vole d=2 #14] refine   cells= {0..3} {4} {5,7} {6,8,9} {10..19}
//!   [vole d=2 #14] branch   cell=2 value=5
//!   [vole d=3 #15] enter
//!   [vole d=3 #15] trace_fail
//!   [vole t=7 #16] sym match     Split { cell: 2, size: 3, reason: .. }
//!   [vole t=8 #17] sym violate   NoSplit { .. }  (expected Split { .. })
//!
//! Trace lines are tagged `t=` (the trace position) rather than `d=`
//! (search depth), since the tracer counts events, not search nodes.
//!
//! The `d=` field is the search depth (0 at the root).  The `#`
//! field is a per-search counter incremented on every event, so
//! adjacent lines that share `#` belong to the same node.  Together
//! they let you locate any event in the search tree without needing
//! to interpret raw search-recurse calls.
//!
//! Adding new event types: drop another `Level::contains_*` and
//! a corresponding `dump_*` here.  Hook sites live in
//! `vole/search/mod.rs` and `vole/partition_stack.rs`.

use std::sync::atomic::{AtomicUsize, Ordering};

use once_cell::sync::Lazy;

use crate::vole::domain_state::DomainState;

bitflags::bitflags! {
    /// Bit-flag selecting which kinds of events to print.
    pub struct DumpLevel: u8 {
        const PARTITION = 0b0001;
        const BRANCH    = 0b0010;
        const TRACE     = 0b0100;
    }
}

impl DumpLevel {
    const FULL: Self = Self::from_bits_truncate(Self::PARTITION.bits | Self::BRANCH.bits | Self::TRACE.bits);

    fn parse(s: &str) -> Self {
        let mut out = Self::empty();
        for tok in s.split([',', ' ', ':']) {
            match tok.trim().to_ascii_lowercase().as_str() {
                "" => {}
                "partition" => out |= Self::PARTITION,
                "branch" => out |= Self::BRANCH,
                "trace" => out |= Self::TRACE,
                "full" | "all" | "1" => out |= Self::FULL,
                other => eprintln!("[vole-diag] unknown VOLE_DUMP token: {:?}", other),
            }
        }
        out
    }
}

/// Active dump level.  Read once on first reference and cached.
static LEVEL: Lazy<DumpLevel> = Lazy::new(|| match std::env::var("VOLE_DUMP") {
    Ok(s) => DumpLevel::parse(&s),
    Err(_) => DumpLevel::empty(),
});

/// Per-search-call event counter.  Each call to a top-level search
/// function (simple_group_search, simple_coset_search, ...) bumps
/// this so all events for one search session share a contiguous
/// range and can be distinguished from events for another search
/// in the same process.
static EVENT_SEQ: AtomicUsize = AtomicUsize::new(0);

#[inline]
fn enabled(flag: DumpLevel) -> bool {
    LEVEL.contains(flag)
}

#[inline]
fn next_seq() -> usize {
    EVENT_SEQ.fetch_add(1, Ordering::Relaxed)
}

/// Format the partition's base cells as a compact set list,
/// collapsing maximal runs of consecutive integers to `{a..b}`.
fn format_cells(cells: &[Vec<usize>]) -> String {
    let mut out = String::new();
    for cell in cells {
        if cell.is_empty() {
            continue;
        }
        out.push_str(" {");
        let mut sorted = cell.clone();
        sorted.sort();
        let mut i = 0;
        let mut first = true;
        while i < sorted.len() {
            let start = sorted[i];
            let mut end = start;
            while i + 1 < sorted.len() && sorted[i + 1] == end + 1 {
                i += 1;
                end = sorted[i];
            }
            if !first {
                out.push(',');
            }
            first = false;
            if start == end {
                out.push_str(&start.to_string());
            } else if end == start + 1 {
                out.push_str(&format!("{},{}", start, end));
            } else {
                out.push_str(&format!("{}..{}", start, end));
            }
            i += 1;
        }
        out.push('}');
    }
    out
}

/// Emit a partition snapshot.  Free when `VOLE_DUMP` is unset or
/// doesn't include `partition`.
pub fn dump_partition(label: &str, depth: usize, state: &DomainState) {
    if !enabled(DumpLevel::PARTITION) {
        return;
    }
    let cells = state.partition().extended_as_list_set();
    eprintln!(
        "[vole d={} #{}] {:<10} cells={}",
        depth,
        next_seq(),
        label,
        format_cells(&cells)
    );
}

/// Emit a branch-choice event.  `cell_size` is included so it's
/// obvious how wide the branching cell was.  `rbase_src` is the
/// rbase value being mapped to `value` — i.e. the assignment we are
/// trying is `rbase_src -> value`.  `None` if we are still building
/// the rbase (left descent).
pub fn dump_branch(depth: usize, cell: usize, value: usize, cell_size: usize, rbase_src: Option<usize>) {
    if !enabled(DumpLevel::BRANCH) {
        return;
    }
    let src = match rbase_src {
        Some(s) => format!("{}", s),
        None => "(rbase)".to_string(),
    };
    eprintln!(
        "[vole d={} #{}] {:<10} cell={} size={} {} -> {}",
        depth,
        next_seq(),
        "branch",
        cell,
        cell_size,
        src,
        value
    );
}

/// Emit a free-form text event (entry / leaf / trace_fail / etc.).
pub fn dump_event(label: &str, depth: usize, detail: &str) {
    if !enabled(DumpLevel::BRANCH) && !enabled(DumpLevel::PARTITION) {
        return;
    }
    eprintln!("[vole d={} #{}] {:<10} {}", depth, next_seq(), label, detail);
}

/// True iff `VOLE_DUMP` requests the tracer-event stream. Callers gate
/// the (non-trivial) `{:?}` formatting of a `TraceEvent` on this, so it
/// costs nothing when the dump is off — `Tracer::add` is on the hot path.
pub fn trace_enabled() -> bool {
    enabled(DumpLevel::TRACE)
}

/// Emit one algorithmic trace event — the Split / NoSplit / refine-fact
/// stream the `Tracer` compares between branches.  `pos` is the trace
/// position, NOT the search-tree depth; the partition / branch dumps use
/// depth, so these lines are tagged `t=` to keep them distinct.  `status`
/// records how the event landed: added (new on this branch), matched /
/// violated the symmetry trace, or new-best / violated the canonical one.
pub fn dump_trace(pos: usize, status: &str, event: &str) {
    if !enabled(DumpLevel::TRACE) {
        return;
    }
    eprintln!("[vole t={} #{}] {:<13} {}", pos, next_seq(), status, event);
}
