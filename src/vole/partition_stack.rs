#![allow(dead_code)]

use crate::vole::trace;
use crate::{
    datastructures::{digraph::Digraph, hash::do_hash},
    perm::Permutation,
};

use std::collections::HashSet;
use std::hash::Hash;

use log::trace;

use super::backtracking::Backtrack;

#[derive(Clone, Debug)]
struct MarkStore {
    marks: Vec<usize>,
}

impl MarkStore {
    fn new(n: usize) -> Self {
        Self {
            marks: vec![0; n + 1],
        }
    }

    fn markof(&self, i: usize) -> usize {
        self.marks[i]
    }

    fn setmarks(&mut self, start: usize, len: usize, cell: usize) {
        for i in start..start + len {
            self.marks[i] = cell;
        }
    }
}

#[derive(Clone, Debug)]
pub struct CellData {
    /// The partition, and it's inverse
    vals: Vec<usize>,
    invvals: Vec<usize>,

    /// Fixed cells, in order of creation
    fixed: Vec<usize>,

    /// Contents of fixed cells, in order of creation
    fixed_vals: Vec<usize>,

    /// Start of cells
    starts: Vec<usize>,

    /// Length of cells
    lengths: Vec<usize>,
}

#[derive(Clone, Debug)]
pub struct PartitionStack {
    /// Size of partition
    pub size: usize,

    cells: CellData,

    marks: MarkStore,

    splits: Vec<usize>,

    saved_depths: Vec<usize>,
}

impl PartitionStack {
    pub fn new(n: usize) -> Self {
        Self {
            size: n,
            cells: CellData {
                vals: (0..n).collect(),
                invvals: (0..n).collect(),
                fixed: vec![],
                fixed_vals: vec![],
                starts: vec![0],
                lengths: vec![n],
            },
            marks: MarkStore::new(n),
            splits: vec![],
            saved_depths: vec![],
        }
    }

    pub fn domain_size(&self) -> usize {
        self.size
    }

    pub fn as_list_set(&self) -> Vec<Vec<usize>> {
        let mut p = vec![];
        for i in 0..self.cells() {
            let mut vec: Vec<usize> = self.cell(i).to_vec();
            vec.sort();
            p.push(vec);
        }
        p
    }

    pub fn cells(&self) -> usize {
        self.cells.starts.len()
    }

    pub fn cell(&self, i: usize) -> &[usize] {
        &self.cells.vals[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    pub fn fixed_cells(&self) -> &[usize] {
        &self.cells.fixed
    }

    pub fn fixed_vals(&self) -> &[usize] {
        &self.cells.fixed_vals
    }

    pub fn cellof(&self, i: usize) -> usize {
        self.marks.markof(self.cells.invvals[i])
    }

    fn sanity_check(&self) {
        {
            let mut valscpy = self.cells.vals.clone();
            valscpy.sort();
            assert_eq!(valscpy, (0..self.size).collect::<Vec<usize>>());
        }
        {
            let mut valsinvcpy = self.cells.invvals.clone();
            valsinvcpy.sort();
            assert_eq!(valsinvcpy, (0..self.size).collect::<Vec<usize>>());
        }
        for i in 0..self.size {
            assert_eq!(self.cells.vals[self.cells.invvals[i]], i);
        }

        assert_eq!(self.cells.fixed.len(), self.cells.fixed_vals.len());

        for i in 0..self.cells.fixed.len() {
            let cell = self.cells.fixed[i];
            assert_eq!(self.cells.lengths[cell], 1);
            assert_eq!(self.cells.fixed_vals[i], self.cell(cell)[0]);
        }

        let mut fixed_count = 0;
        for i in 0..self.cells() {
            if self.cell(i).len() == 1 {
                fixed_count += 1;
                assert!(self.cells.fixed.contains(&i));
            }
        }

        assert_eq!(self.cells.fixed.len(), fixed_count);

        assert_eq!(self.cells.starts.len(), self.cells.lengths.len());

        let mut starts: HashSet<usize> = self.cells.starts.iter().cloned().collect();
        assert_eq!(starts.len(), self.cells.starts.len());
        starts.insert(self.size);

        assert!(starts.contains(&0));
        assert_eq!(self.cells.lengths.iter().sum::<usize>(), self.size);
        for i in 0..self.cells() {
            assert!(starts.contains(&(self.cells.starts[i] + self.cells.lengths[i])));
        }
        for i in 0..self.cells() {
            for j in self.cell(i) {
                assert_eq!(self.cellof(*j), i);
            }
        }
    }

    fn split_cell(&mut self, cell: usize, pos: usize) {
        debug_assert!(pos > 0 && pos < self.cells.lengths[cell]);

        self.splits.push(cell);

        let new_cell_num = self.cells.starts.len();

        let new_cell_start = self.cells.starts[cell] + pos;
        let old_cell_new_size = pos;
        let new_cell_size = self.cells.lengths[cell] - pos;

        self.cells.lengths[cell] = old_cell_new_size;
        self.cells.starts.push(new_cell_start);
        self.cells.lengths.push(new_cell_size);

        if new_cell_size == 1 {
            self.cells.fixed.push(new_cell_num);
            self.cells.fixed_vals.push(self.cells.vals[new_cell_start]);
        }
        if old_cell_new_size == 1 {
            self.cells.fixed.push(cell);
            self.cells
                .fixed_vals
                .push(self.cells.vals[self.cells.starts[cell]]);
        }

        self.marks
            .setmarks(new_cell_start, new_cell_size, new_cell_num);
    }

    fn unsplit_cell(&mut self) {
        let unsplit = self.splits.pop().unwrap();

        let cell_start = self.cells.starts.pop().unwrap();
        let cell_length = self.cells.lengths.pop().unwrap();

        self.marks.setmarks(cell_start, cell_length, unsplit);

        if cell_length == 1 {
            self.cells.fixed_vals.pop();
            self.cells.fixed.pop();
        }

        if self.cells.lengths[unsplit] == 1 {
            self.cells.fixed_vals.pop();
            self.cells.fixed.pop();
        }

        self.cells.lengths[unsplit] += cell_length;
    }

    fn unsplit_cells_to(&mut self, cells: usize) {
        debug_assert!(self.cells() >= cells);
        while self.cells() > cells {
            self.unsplit_cell();
        }
    }
}

impl Backtrack for PartitionStack {
    fn save_state(&mut self) {
        self.saved_depths.push(self.cells());
    }

    fn restore_state(&mut self) {
        let depth = self.saved_depths.pop().unwrap();
        self.unsplit_cells_to(depth);
    }
}

impl PartitionStack {
    /// The following methods are highly unsafe, and must be used with care.
    fn mut_cell(&mut self, i: usize) -> &mut [usize] {
        &mut self.cells.vals[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    fn mut_fix_cell_inverses(&mut self, i: usize) {
        for j in self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i] {
            self.cells.invvals[self.cells.vals[j]] = j;
        }
    }

    pub fn refine_partition_cell_by<F: Copy, O: Ord + Hash>(
        &mut self,
        tracer: &mut trace::Tracer,
        i: usize,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> O,
    {
        tracer.add(trace::TraceEvent::Start())?;
        {
            let cell_slice = self.mut_cell(i);
            cell_slice.sort_by_key(f);
        }
        self.mut_fix_cell_inverses(i);
        {
            let cellstart = self.cells.starts[i];
            // First cell is never split
            tracer.add(trace::TraceEvent::NoSplit {
                cell: i,
                reason: trace::hash(&f(&self.cells.vals[cellstart])),
            })?;
            for p in (1..self.cells.lengths[i]).rev() {
                if f(&self.cells.vals[cellstart + p]) != f(&self.cells.vals[cellstart + p - 1]) {
                    self.split_cell(i, p);
                    let val = f(&self.cells.vals[cellstart + p - 1]);

                    tracer.add(trace::TraceEvent::Split {
                        cell: i,
                        size: p,
                        reason: trace::hash(&val),
                    })?
                }
            }
        }
        tracer.add(trace::TraceEvent::End())?;
        Ok(())
    }

    pub fn refine_partition_by<F: Copy, O: Ord + Hash>(
        &mut self,
        tracer: &mut trace::Tracer,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> O,
    {
        for i in 0..self.cells() {
            self.refine_partition_cell_by(tracer, i, f)?;
        }
        Ok(())
    }

    pub fn refine_partition_cells_by_graph<I>(
        &mut self,
        tracer: &mut trace::Tracer,
        d: &Digraph,
        cells: I,
    ) -> trace::Result<()>
    where
        I: IntoIterator<Item = usize>,
    {
        let mut seen_cells = HashSet::<usize>::new();

        let mut points = vec![0; self.domain_size()];

        for c in cells {
            for p in self.cell(c) {
                for (&neighbour, &colour) in d.neighbours(*p) {
                    points[neighbour] += do_hash((c, colour));
                    seen_cells.insert(self.cellof(neighbour));
                }
            }
        }

        for s in seen_cells {
            self.refine_partition_cell_by(tracer, s, |x| points[*x])?;
        }
        Ok(())
    }

    pub fn refine_partition_by_graph(
        &mut self,
        tracer: &mut trace::Tracer,
        d: &Digraph,
    ) -> trace::Result<()> {
        self.refine_partition_cells_by_graph(tracer, d, 0..self.cells())
    }
}

pub fn perm_between(lhs: &PartitionStack, rhs: &PartitionStack) -> Permutation {
    assert!(lhs.cells() == lhs.domain_size());
    assert!(rhs.cells() == rhs.domain_size());
    assert!(lhs.domain_size() == rhs.domain_size());
    let mut perm = vec![0; rhs.domain_size()];
    trace!(
        "{:?}:{:?}:{:?}",
        lhs.fixed_vals(),
        rhs.fixed_vals(),
        rhs.domain_size()
    );
    for i in 0..rhs.domain_size() {
        perm[lhs.fixed_vals()[i]] = rhs.fixed_vals()[i];
    }

    Permutation::from_vec(perm)
}

#[cfg(test)]
mod tests {
    use super::perm_between;
    use super::PartitionStack;
    use super::Permutation;
    use crate::{datastructures::digraph::Digraph, vole::trace};

    #[test]
    fn basic() {
        let p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.domain_size(), 5);
        assert_eq!(p.cells(), 1);
        for i in 0..5 {
            assert_eq!(p.cellof(i), 0);
        }

        let mut slice = p.cell(0).to_vec();
        slice.sort();
        assert_eq!(slice, (0..5).collect::<Vec<usize>>());

        p.sanity_check();
    }

    #[test]
    fn test_split() {
        let mut p = PartitionStack::new(5);
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.split_cell(0, 2);
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2, 3, 4]]);
        p.sanity_check();
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.sanity_check();
        p.split_cell(0, 3);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.sanity_check();
        p.split_cell(0, 1);
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.split_cell(1, 1);
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3], vec![1, 2], vec![4]]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
    }

    #[test]
    fn test_refine() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        p.sanity_check();
        // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        p.sanity_check();
        p.refine_partition_by(&mut tracer, |x| *x > 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2], vec![3, 4]]);
        p.sanity_check();
        Ok(())
    }

    #[test]
    fn test_refine2() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x % 2 != 0)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x % 2 != 0)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(&mut tracer, |x| *x < 2)?;
        assert_eq!(p.as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.unsplit_cells_to(2);
        // Do twice, as splitting rearranges internal values
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(&mut tracer, |x| *x < 2)?;
        assert_eq!(p.as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.unsplit_cells_to(2);
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(&mut tracer, |x| *x >= 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0], vec![1], vec![2, 4], vec![3]]);
        p.sanity_check();
        p.unsplit_cell();
        Ok(())
    }

    #[test]
    fn test_refine_graph() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        let d = Digraph::empty(5);
        p.refine_partition_by_graph(&mut tracer, &d)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        let d2 = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![], vec![]]);
        p.refine_partition_by_graph(&mut tracer, &d2)?;
        assert_eq!(p.as_list_set(), vec![vec![3, 4], vec![0, 1, 2]]);
        p.sanity_check();
        // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        let d2 = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![], vec![]]);
        p.refine_partition_by_graph(&mut tracer, &d2)?;
        assert_eq!(p.as_list_set(), vec![vec![3, 4], vec![0, 1, 2]]);
        p.sanity_check();
        Ok(())
    }

    #[test]
    fn test_perm() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        let mut q = PartitionStack::new(5);
        p.refine_partition_by(&mut tracer, |x| *x)?;
        q.refine_partition_by(&mut tracer, |x| *x)?;
        assert_eq!(perm_between(&p, &q), Permutation::id());
        Ok(())
    }

    #[test]
    fn test_perm2() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        let mut q = PartitionStack::new(5);
        p.refine_partition_by(&mut tracer, |x| 10 - *x)?;
        q.refine_partition_by(&mut tracer, |x| *x)?;
        assert_eq!(
            perm_between(&p, &q),
            Permutation::from_vec(vec![4, 3, 2, 1, 0])
        );
        Ok(())
    }
}
