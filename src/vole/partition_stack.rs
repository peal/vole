#![allow(dead_code)]

use crate::vole::trace;
use crate::{
    datastructures::{digraph::Digraph, hash::do_hash},
    perm::Permutation,
};

use std::hash::Hash;
use std::{collections::HashSet, num::Wrapping};

use tracing::info;

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

    fn mark_of(&self, i: usize) -> usize {
        self.marks[i]
    }

    fn set_marks(&mut self, start: usize, len: usize, cell: usize) {
        for i in start..start + len {
            self.marks[i] = cell;
        }
    }
}

#[derive(Clone, Debug)]
pub struct CellData {
    /// The partition, and it's inverse
    values: Vec<usize>,
    inv_values: Vec<usize>,

    /// Fixed cells, in order of creation
    base_fixed: Vec<usize>,

    /// Contents of fixed cells, in order of creation
    base_fixed_values: Vec<usize>,

    /// Start of cells
    starts: Vec<usize>,

    /// Length of cells
    lengths: Vec<usize>,

    /// Cells in the base partition
    base_cells: Vec<usize>,
}

#[derive(Clone, Debug)]
pub struct PartitionStack {
    /// Size of partition
    pub base_size: usize,

    cells: CellData,

    marks: MarkStore,

    splits: Vec<usize>,

    saved_depths: Vec<usize>,
}

impl PartitionStack {
    pub fn new(n: usize) -> Self {
        Self {
            base_size: n,
            cells: CellData {
                values: (0..n).collect(),
                inv_values: (0..n).collect(),
                base_fixed: vec![],
                base_fixed_values: vec![],
                starts: vec![0],
                lengths: vec![n],
                base_cells: vec![0],
            },
            marks: MarkStore::new(n),
            splits: vec![],
            saved_depths: vec![],
        }
    }

    pub fn base_domain_size(&self) -> usize {
        self.base_size
    }

    pub fn as_list_set(&self) -> Vec<Vec<usize>> {
        let mut p = vec![];
        for &i in self.base_cells() {
            let mut vec: Vec<usize> = self.cell(i).to_vec();
            vec.sort();
            p.push(vec);
        }
        p
    }

    pub fn as_indicator(&self) -> Vec<usize> {
        let mut p = vec![0; self.base_domain_size()];
        for &i in self.base_cells() {
            for &c in self.cell(i) {
                p[c] = i;
            }
        }
        p
    }
    pub fn base_cells(&self) -> &[usize] {
        self.cells.base_cells.as_slice()
    }

    pub fn cell(&self, i: usize) -> &[usize] {
        &self.cells.values[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    pub fn base_fixed_cells(&self) -> &[usize] {
        &self.cells.base_fixed
    }

    pub fn base_fixed_values(&self) -> &[usize] {
        &self.cells.base_fixed_values
    }

    pub fn cell_of(&self, i: usize) -> usize {
        self.marks.mark_of(self.cells.inv_values[i])
    }

    fn sanity_check(&self) {
        {
            let mut values_cpy = self.cells.values.clone();
            values_cpy.sort();
            assert_eq!(values_cpy, (0..self.base_size).collect::<Vec<usize>>());
        }
        {
            let mut inv_values_cpy = self.cells.inv_values.clone();
            inv_values_cpy.sort();
            assert_eq!(inv_values_cpy, (0..self.base_size).collect::<Vec<usize>>());
        }
        for i in 0..self.base_size {
            assert_eq!(self.cells.values[self.cells.inv_values[i]], i);
        }

        assert_eq!(
            self.cells.base_fixed.len(),
            self.cells.base_fixed_values.len()
        );

        for i in 0..self.cells.base_fixed.len() {
            let cell = self.cells.base_fixed[i];
            assert_eq!(self.cells.lengths[cell], 1);
            assert_eq!(self.cells.base_fixed_values[i], self.cell(cell)[0]);
        }

        let mut fixed_count = 0;
        for &i in self.base_cells() {
            if self.cell(i).len() == 1 {
                fixed_count += 1;
                assert!(self.cells.base_fixed.contains(&i));
            }
        }

        assert_eq!(self.cells.base_fixed.len(), fixed_count);

        assert_eq!(self.cells.starts.len(), self.cells.lengths.len());

        let mut starts: HashSet<usize> = self.cells.starts.iter().cloned().collect();
        assert_eq!(starts.len(), self.cells.starts.len());
        starts.insert(self.base_size);

        assert!(starts.contains(&0));
        assert_eq!(self.cells.lengths.iter().sum::<usize>(), self.base_size);
        for &i in self.base_cells() {
            assert!(starts.contains(&(self.cells.starts[i] + self.cells.lengths[i])));
        }
        for &i in self.base_cells() {
            for j in self.cell(i) {
                assert_eq!(self.cell_of(*j), i);
            }
        }
    }

    fn split_cell(&mut self, cell: usize, pos: usize) {
        debug_assert!(pos > 0 && pos < self.cells.lengths[cell]);

        self.splits.push(cell);

        let new_cell_num = self.cells.starts.len();

        self.cells.base_cells.push(new_cell_num);

        let new_cell_start = self.cells.starts[cell] + pos;
        let old_cell_new_size = pos;
        let new_cell_size = self.cells.lengths[cell] - pos;

        self.cells.lengths[cell] = old_cell_new_size;
        self.cells.starts.push(new_cell_start);
        self.cells.lengths.push(new_cell_size);

        if new_cell_size == 1 {
            self.cells.base_fixed.push(new_cell_num);
            self.cells
                .base_fixed_values
                .push(self.cells.values[new_cell_start]);
        }
        if old_cell_new_size == 1 {
            self.cells.base_fixed.push(cell);
            self.cells
                .base_fixed_values
                .push(self.cells.values[self.cells.starts[cell]]);
        }

        self.marks
            .set_marks(new_cell_start, new_cell_size, new_cell_num);
    }

    fn unsplit_cell(&mut self) {
        let unsplit = self.splits.pop().unwrap();

        let _ = self.cells.base_cells.pop().unwrap();

        let cell_start = self.cells.starts.pop().unwrap();
        let cell_length = self.cells.lengths.pop().unwrap();

        self.marks.set_marks(cell_start, cell_length, unsplit);

        if cell_length == 1 {
            self.cells.base_fixed_values.pop();
            self.cells.base_fixed.pop();
        }

        if self.cells.lengths[unsplit] == 1 {
            self.cells.base_fixed_values.pop();
            self.cells.base_fixed.pop();
        }

        self.cells.lengths[unsplit] += cell_length;
    }

    fn unsplit_cells_to(&mut self, cells: usize) {
        debug_assert!(self.base_cells().len() >= cells);
        while self.base_cells().len() > cells {
            self.unsplit_cell();
        }
    }
}

impl Backtrack for PartitionStack {
    fn save_state(&mut self) {
        self.saved_depths.push(self.base_cells().len());
    }

    fn restore_state(&mut self) {
        let depth = self.saved_depths.pop().unwrap();
        self.unsplit_cells_to(depth);
    }
}

impl PartitionStack {
    /// The following methods are highly unsafe, and must be used with care.
    fn mut_cell(&mut self, i: usize) -> &mut [usize] {
        &mut self.cells.values[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    fn mut_fix_cell_inverses(&mut self, i: usize) {
        for j in self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i] {
            self.cells.inv_values[self.cells.values[j]] = j;
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
            let cell_start = self.cells.starts[i];
            // First cell is never split
            tracer.add(trace::TraceEvent::NoSplit {
                cell: i,
                reason: trace::hash(&f(&self.cells.values[cell_start])),
            })?;
            for p in (1..self.cells.lengths[i]).rev() {
                if f(&self.cells.values[cell_start + p])
                    != f(&self.cells.values[cell_start + p - 1])
                {
                    self.split_cell(i, p);
                    let val = f(&self.cells.values[cell_start + p - 1]);

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
        let mut pos = 0;
        while pos < self.base_cells().len() {
            let c = self.base_cells()[pos];
            self.refine_partition_cell_by(tracer, c, f)?;
            pos += 1;
        }
        Ok(())
    }

    pub fn refine_partition_cells_by_graph(
        &mut self,
        tracer: &mut trace::Tracer,
        d: &Digraph,
        first_cell: usize,
    ) -> trace::Result<()> {
        let mut seen_cells = HashSet::<usize>::new();

        let mut points = vec![Wrapping(0usize); self.base_domain_size()];

        let mut pos = first_cell;
        while pos < self.base_cells().len() {
            let c = self.base_cells()[pos];
            for p in self.cell(c) {
                for (&neighbour, &colour) in d.neighbours(*p) {
                    points[neighbour] += do_hash((c, colour));
                    seen_cells.insert(self.cell_of(neighbour));
                }
            }
            pos += 1;
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
        self.refine_partition_cells_by_graph(tracer, d, 0)
    }
}

pub fn perm_between(lhs: &PartitionStack, rhs: &PartitionStack) -> Permutation {
    assert!(lhs.base_cells().len() == lhs.base_domain_size());
    assert!(rhs.base_cells().len() == rhs.base_domain_size());
    assert!(lhs.base_domain_size() == rhs.base_domain_size());
    let mut perm = vec![0; rhs.base_domain_size()];
    info!(
        "{:?}:{:?}:{:?}",
        lhs.base_fixed_values(),
        rhs.base_fixed_values(),
        rhs.base_domain_size()
    );
    for i in 0..rhs.base_domain_size() {
        perm[lhs.base_fixed_values()[i]] = rhs.base_fixed_values()[i];
    }

    Permutation::from_vec(perm)
}

#[cfg(test)]
mod tests {
    use test_env_log::test;

    use super::perm_between;
    use super::PartitionStack;
    use super::Permutation;
    use crate::{
        datastructures::digraph::Digraph,
        vole::{backtracking::Backtrack, trace},
    };

    #[test]
    fn basic() {
        let p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        assert_eq!(p.base_domain_size(), 5);
        assert_eq!(p.base_cells(), vec![0]);
        for i in 0..5 {
            assert_eq!(p.cell_of(i), 0);
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
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        p.split_cell(0, 2);
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 1, 1, 1]);
        p.sanity_check();
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        p.sanity_check();
        p.split_cell(0, 3);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.sanity_check();
        p.split_cell(0, 1);
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.split_cell(1, 1);
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3], vec![1, 2], vec![4]]);
        assert_eq!(p.as_indicator(), vec![0, 2, 2, 1, 3]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        assert_eq!(p.as_indicator(), vec![0, 2, 2, 1, 1]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.unsplit_cell();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
    }

    #[test]
    fn test_split_state() {
        let mut p = PartitionStack::new(5);
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        p.save_state();
        p.split_cell(0, 2);
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 1, 1, 1]);
        p.sanity_check();
        p.restore_state();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        p.sanity_check();
        p.save_state();
        p.save_state();
        p.split_cell(0, 3);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.sanity_check();
        p.split_cell(0, 1);
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.split_cell(1, 1);
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0], vec![3], vec![1, 2], vec![4]]);
        assert_eq!(p.as_indicator(), vec![0, 2, 2, 1, 3]);
        p.restore_state();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
        p.restore_state();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 0, 0, 0]);
    }

    #[test]
    fn test_refine() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 1, 0, 0]);
        p.sanity_check();
        // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 1, 0, 0]);
        p.sanity_check();
        p.refine_partition_by(&mut tracer, |x| *x > 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2], vec![3, 4]]);
        assert_eq!(p.as_indicator(), vec![0, 0, 1, 2, 2]);
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
