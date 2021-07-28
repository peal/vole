#![allow(dead_code)]

use crate::{
    datastructures::{digraph::Digraph, hash::QuickHashable},
    perm::Permutation,
};
use crate::{
    datastructures::{hash::QHash, small_int_set::SmallIntSet},
    vole::trace,
};

use std::fmt::Debug;
use std::hash::Hash;
use std::{collections::HashSet, num::Wrapping};

use itertools::Itertools;
use tracing::info;

use super::backtracking::Backtrack;

#[derive(Clone, Debug)]
struct MarkStore {
    marks: Vec<usize>,
}

impl MarkStore {
    fn new(n: usize) -> Self {
        Self { marks: vec![0; n] }
    }

    fn mark_of(&self, i: usize) -> usize {
        self.marks[i]
    }

    fn set_marks(&mut self, start: usize, len: usize, cell: usize) {
        for i in start..start + len {
            self.marks[i] = cell;
        }
    }

    fn extend_marks(&mut self, extra: usize, cell: usize) {
        self.marks.resize(self.marks.len() + extra, cell);
    }

    fn remove_marks(&mut self, extra: usize) {
        debug_assert!(self.marks.len() >= extra);
        self.marks.truncate(self.marks.len() - extra);
    }
}

/// Data about the partition
#[derive(Clone, Debug)]
pub struct CellData {
    /// The partition, and its inverse
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

    /// Cells in the extended partition
    extended_cells: Vec<usize>,
}

/// An ordered partition of a set [1..n], which support many operations, including:
/// * Split cells
/// * Which which cell a value is contained in
/// * Save the current state of the partition (to be reverted to later)
/// * (Non-standard) - Extend the partition with a new cell, containing new integers
///
/// Several functions refer to 'base' and 'extended'. 'base' refers to the original
/// values [1..n] which the partition was originally created with, while 'extended'
/// functions also include any values added after the partition is created.
#[derive(Clone, Debug)]
pub struct PartitionStack {
    /// Initial size of partition
    pub base_size: usize,

    /// Extended size of partition
    pub extended_size: usize,

    cells: CellData,

    marks: MarkStore,

    splits: Vec<usize>,

    saved_depths: Vec<usize>,
}

impl PartitionStack {
    /// Create a new partition which contains a single cell with [1..`n`]
    pub fn new(n: usize) -> Self {
        // Don't want to handle 0 and 1, as such problems are trivial anyway
        assert!(n > 1);
        Self {
            base_size: n,
            extended_size: n,
            cells: CellData {
                values: (0..n).collect(),
                inv_values: (0..n).collect(),
                base_fixed: vec![],
                base_fixed_values: vec![],
                starts: vec![0],
                lengths: vec![n],
                base_cells: vec![0],
                extended_cells: vec![0],
            },
            marks: MarkStore::new(n),
            splits: vec![],
            saved_depths: vec![],
        }
    }

    /// Add a new cell which contains `extra` new numbers, returns id of new partition
    pub fn extend(&mut self, extra: usize) -> usize {
        assert!(extra > 0);
        let cur_size = self.extended_size;
        let new_size = cur_size + extra;
        let new_cell = self.cells.starts.len();
        self.extended_size += extra;
        self.cells.values.extend(cur_size..new_size);
        self.cells.inv_values.extend(cur_size..new_size);
        self.cells.starts.push(cur_size);
        self.cells.lengths.push(extra);
        // Don't add to 'base_cells'
        self.cells.extended_cells.push(new_cell);
        self.marks.extend_marks(extra, new_cell);
        debug_assert!(self.sanity_check());

        // usize::MAX denotes the extra cell was created by adding to the partition
        self.splits.push(usize::MAX);
        new_cell
    }

    fn revert_extend(&mut self) {
        // Get the size of the extra added cell
        let extra = self.cells.lengths.pop().unwrap();

        let cur_size = self.extended_size;
        let new_size = cur_size - extra;

        self.extended_size -= extra;

        let cell = self.cells.starts.len() - 1;

        self.cells.values.truncate(self.extended_size);
        self.cells.inv_values.truncate(self.extended_size);
        let pop_starts = self.cells.starts.pop();
        assert_eq!(pop_starts.unwrap(), new_size);

        self.marks.remove_marks(extra);
        let pop_extended_cells = self.cells.extended_cells.pop();
        assert_eq!(pop_extended_cells.unwrap(), cell);
    }

    /// Original size of partition when it was created
    pub fn base_domain_size(&self) -> usize {
        self.base_size
    }

    /// Size of partition with any extra values added since creation.
    pub fn extended_domain_size(&self) -> usize {
        self.extended_size
    }

    fn as_list_set(&self, cells: &[usize]) -> Vec<Vec<usize>> {
        let mut p = vec![];
        for &i in cells {
            let mut vec: Vec<usize> = self.cell(i).to_vec();
            vec.sort();
            p.push(vec);
        }
        p
    }

    /// Convert partition to a list of ordered lists (include only 'base' values)
    pub fn base_as_list_set(&self) -> Vec<Vec<usize>> {
        self.as_list_set(self.base_cells())
    }

    /// Convert partition to a list of ordered lists (include 'extended' values)
    pub fn extended_as_list_set(&self) -> Vec<Vec<usize>> {
        self.as_list_set(self.extended_cells())
    }

    /// Convert partition to an indicator function (include only 'base' values)
    pub fn base_as_indicator(&self) -> Vec<usize> {
        let mut p = vec![0; self.base_domain_size()];
        for &i in self.base_cells() {
            for &c in self.cell(i) {
                p[c] = i;
            }
        }
        p
    }

    /// Convert partition to an indicator function (include 'extended' values)
    pub fn extended_as_indicator(&self) -> Vec<usize> {
        let mut p = vec![0; self.extended_domain_size()];
        for &i in self.extended_cells() {
            for &c in self.cell(i) {
                p[c] = i;
            }
        }
        p
    }

    /// Get list of all cells including 'base' values (which many not be a contigous list)
    pub fn base_cells(&self) -> &[usize] {
        self.cells.base_cells.as_slice()
    }

    /// Get list of all cells including 'extended' values (which many not be a contigous list)
    pub fn extended_cells(&self) -> &[usize] {
        self.cells.extended_cells.as_slice()
    }

    /// Contents of cell `i`
    pub fn cell(&self, i: usize) -> &[usize] {
        &self.cells.values[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    /// Cells containing base values which are of size 1, in the order they were fixed
    pub fn base_fixed_cells(&self) -> &[usize] {
        &self.cells.base_fixed
    }

    /// The values in cells containins base values which are of size 1, in the order they were fixed
    pub fn base_fixed_values(&self) -> &[usize] {
        &self.cells.base_fixed_values
    }

    /// Cell which contains `i`
    pub fn cell_of(&self, i: usize) -> usize {
        self.marks.mark_of(self.cells.inv_values[i])
    }

    fn sanity_check(&self) -> bool {
        // Check values is a permutation
        {
            let mut values_cpy = self.cells.values.clone();
            values_cpy.sort();
            assert_eq!(values_cpy, (0..self.extended_size).collect::<Vec<usize>>());
        }
        // Check inv_values is a permutation
        {
            let mut inv_values_cpy = self.cells.inv_values.clone();
            inv_values_cpy.sort();
            assert_eq!(inv_values_cpy, (0..self.extended_size).collect::<Vec<usize>>());
        }
        // Check values[inv_values[i]] == i
        for i in 0..self.base_size {
            assert_eq!(self.cells.values[self.cells.inv_values[i]], i);
        }

        // check base_fixed and base_fixed_values contain the cells of size 1,
        // and the value in those cells respectively (only in the original 'base')
        assert_eq!(self.cells.base_fixed.len(), self.cells.base_fixed_values.len());

        for i in 0..self.cells.base_fixed.len() {
            let cell = self.cells.base_fixed[i];
            assert_eq!(self.cells.lengths[cell], 1);
            assert_eq!(self.cells.base_fixed_values[i], self.cell(cell)[0]);
        }

        let mut fixed_count = 0;
        for &i in self.base_cells() {
            if self.cell(i).len() == 1 {
                let val = self.cell(i)[0];
                if val < self.base_size {
                    fixed_count += 1;
                    assert!(self.cells.base_fixed.contains(&i));
                } else {
                    assert!(!self.cells.base_fixed.contains(&i));
                }
            }
        }

        assert_eq!(self.cells.base_fixed.len(), fixed_count);

        // Check the cell starts, and lengths, have the same size
        assert_eq!(self.cells.starts.len(), self.cells.lengths.len());

        let mut starts: HashSet<usize> = self.cells.starts.iter().cloned().collect();
        assert_eq!(starts.len(), self.cells.starts.len());
        // This is so we have the end of every cell
        starts.insert(self.extended_size);

        // Check some cell starts at position 0
        assert!(starts.contains(&0));
        // Check the sum of the sizes of cells is correct
        assert_eq!(self.cells.lengths.iter().sum::<usize>(), self.extended_size);
        // Make sure a cell starts wherever another ends
        for &i in self.extended_cells() {
            assert!(starts.contains(&(self.cells.starts[i] + self.cells.lengths[i])));
        }
        // Check every value is in the correct cell
        for &i in self.extended_cells() {
            for j in self.cell(i) {
                assert_eq!(self.cell_of(*j), i);
            }
        }
        true
    }

    fn split_cell(&mut self, cell: usize, pos: usize) {
        debug_assert!(pos > 0 && pos < self.cells.lengths[cell]);

        let splitting_a_base_cell = self.cell(cell)[0] < self.base_size;

        self.splits.push(cell);

        let new_cell_num = self.cells.starts.len();

        if splitting_a_base_cell {
            self.cells.base_cells.push(new_cell_num);
        }
        self.cells.extended_cells.push(new_cell_num);

        let new_cell_start = self.cells.starts[cell] + pos;
        let old_cell_new_size = pos;
        let new_cell_size = self.cells.lengths[cell] - pos;

        self.cells.lengths[cell] = old_cell_new_size;
        self.cells.starts.push(new_cell_start);
        self.cells.lengths.push(new_cell_size);

        if new_cell_size == 1 && splitting_a_base_cell {
            self.cells.base_fixed.push(new_cell_num);
            self.cells.base_fixed_values.push(self.cells.values[new_cell_start]);
        }
        if old_cell_new_size == 1 && splitting_a_base_cell {
            self.cells.base_fixed.push(cell);
            self.cells
                .base_fixed_values
                .push(self.cells.values[self.cells.starts[cell]]);
        }

        self.marks.set_marks(new_cell_start, new_cell_size, new_cell_num);
    }

    fn unsplit_cell(&mut self) {
        let unsplit = self.splits.pop().unwrap();

        if unsplit == usize::MAX {
            // This was a newly created cell
            self.revert_extend();
            return;
        }

        let splitting_a_base_cell = self.cell(unsplit)[0] < self.base_size;

        if splitting_a_base_cell {
            let _ = self.cells.base_cells.pop().unwrap();
        }
        let _ = self.cells.extended_cells.pop().unwrap();

        let cell_start = self.cells.starts.pop().unwrap();
        let cell_length = self.cells.lengths.pop().unwrap();

        self.marks.set_marks(cell_start, cell_length, unsplit);

        if cell_length == 1 && splitting_a_base_cell {
            self.cells.base_fixed_values.pop();
            self.cells.base_fixed.pop();
        }

        if self.cells.lengths[unsplit] == 1 && splitting_a_base_cell {
            self.cells.base_fixed_values.pop();
            self.cells.base_fixed.pop();
        }

        self.cells.lengths[unsplit] += cell_length;
    }

    fn extended_unsplit_cells_to(&mut self, cells: usize) {
        debug_assert!(self.extended_cells().len() >= cells);
        while self.extended_cells().len() > cells {
            self.unsplit_cell();
        }
    }
}

impl Backtrack for PartitionStack {
    fn save_state(&mut self) {
        self.saved_depths.push(self.extended_cells().len());
    }

    fn restore_state(&mut self) {
        let depth = self.saved_depths.pop().unwrap();
        self.extended_unsplit_cells_to(depth);
    }

    fn state_depth(&self) -> usize {
        self.saved_depths.len()
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

    pub fn refine_partition_cell_by<F: Copy, O: Ord + Hash + Debug + QuickHashable>(
        &mut self,
        tracer: &mut trace::Tracer,
        i: usize,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> O,
    {
        let cell_slice = self.mut_cell(i);
        if cell_slice.len() == 1 {
            return Ok(());
        }
        {
            if cell_slice.iter().map(|x| f(x)).all_equal() {
                let hash = f(&cell_slice[0]).quick_hash();
                // Reduce info size
                if cell_slice.len() > 1 {
                    info!(target: "tracer", "Trace all equal: {:?}, len {:?}", hash, cell_slice.len());
                }
                // Early Exit for cell of size 1
                tracer.add(trace::TraceEvent::NoSplit {
                    cell: i,
                    reason: hash.0,
                })?;
                return Ok(());
            }
            cell_slice.sort_by_key(f);
        }
        info!(target: "tracer", "Traces: {:?}", (self.cell(i).iter().map(|x| f(x)).collect::<Vec<_>>()));
        self.mut_fix_cell_inverses(i);
        {
            let cell_start = self.cells.starts[i];
            // First cell is never split
            tracer.add(trace::TraceEvent::NoSplit {
                cell: i,
                reason: f(&self.cells.values[cell_start]).quick_hash().0,
            })?;
            for p in (1..self.cells.lengths[i]).rev() {
                if f(&self.cells.values[cell_start + p]) != f(&self.cells.values[cell_start + p - 1]) {
                    self.split_cell(i, p);
                    let val = f(&self.cells.values[cell_start + p - 1]);

                    tracer.add(trace::TraceEvent::Split {
                        cell: i,
                        size: p,
                        reason: val.quick_hash().0,
                    })?
                }
            }
        }
        tracer.add(trace::TraceEvent::End())?;
        Ok(())
    }

    pub fn base_refine_partition_by<F: Copy, O: Ord + Hash + Debug + QuickHashable>(
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

    pub fn extended_refine_partition_by<F: Copy, O: Ord + Hash + Debug + QuickHashable>(
        &mut self,
        tracer: &mut trace::Tracer,
        f: F,
    ) -> trace::Result<()>
    where
        F: Fn(&usize) -> O,
    {
        let mut pos = 0;
        while pos < self.extended_cells().len() {
            let c = self.extended_cells()[pos];
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
        let mut cells_done = first_cell;
        while cells_done < self.extended_cells().len() {
            let mut seen_cells = SmallIntSet::new(self.extended_domain_size());

            let mut points = vec![Wrapping(0 as QHash); self.extended_domain_size()];

            while cells_done < self.extended_cells().len() {
                let c = self.extended_cells()[cells_done];
                // Use a slightly less good hashing strategy, as this bit of code is the hotest piece of code
                let c_hash = c.quick_hash();
                for &p in self.cell(c) {
                    for (&neighbour, &colour) in d.neighbours(p) {
                        points[neighbour] += c_hash * colour; // TODO: Benchmark against (c, colour).quick_hash();
                        seen_cells.insert(self.cell_of(neighbour));
                    }
                }
                cells_done += 1;
            }

            //dbg!(format!("{:?}",&points));
            // This may increment self.extended_cells().len(), which is why we look around
            //dbg!(format!("{:?}",self.extended_as_list_set()));
            for &s in seen_cells.sorted_iter() {
                self.refine_partition_cell_by(tracer, s, |x| points[*x])?;
            }
            //dbg!(format!("{:?}",self.extended_as_list_set()));
        }
        Ok(())
    }

    pub fn refine_partition_by_graph(&mut self, tracer: &mut trace::Tracer, d: &Digraph) -> trace::Result<()> {
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
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
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
        assert_eq!(p.state_depth(), 0);
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
        p.split_cell(0, 2);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1], vec![2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 1, 1, 1]);
        p.sanity_check();
        p.unsplit_cell();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
        p.sanity_check();
        p.split_cell(0, 3);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.sanity_check();
        p.split_cell(0, 1);
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.split_cell(1, 1);
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![3], vec![1, 2], vec![4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 2, 2, 1, 3]);
        p.unsplit_cell();
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 2, 2, 1, 1]);
        p.unsplit_cell();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.unsplit_cell();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
    }

    #[test]
    fn test_split_state() {
        let mut p = PartitionStack::new(5);
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
        assert_eq!(p.state_depth(), 0);
        p.save_state();
        assert_eq!(p.state_depth(), 1);
        p.split_cell(0, 2);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1], vec![2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 1, 1, 1]);
        p.sanity_check();
        assert_eq!(p.state_depth(), 1);
        p.restore_state();
        assert_eq!(p.state_depth(), 0);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
        p.sanity_check();
        assert_eq!(p.state_depth(), 0);
        p.save_state();
        assert_eq!(p.state_depth(), 1);
        p.save_state();
        assert_eq!(p.state_depth(), 2);
        p.split_cell(0, 3);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2], vec![3, 4]]);
        p.sanity_check();
        p.split_cell(0, 1);
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![3, 4], vec![1, 2]]);
        p.split_cell(1, 1);
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![3], vec![1, 2], vec![4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 2, 2, 1, 3]);
        assert_eq!(p.state_depth(), 2);
        p.restore_state();
        assert_eq!(p.state_depth(), 1);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
        p.restore_state();
        assert_eq!(p.state_depth(), 0);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 0, 0, 0]);
    }

    #[test]
    fn test_refine() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.base_refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 1, 0, 0]);
        p.sanity_check();
        // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.base_refine_partition_by(&mut tracer, |x| *x == 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 1, 0, 0]);
        p.sanity_check();
        p.base_refine_partition_by(&mut tracer, |x| *x > 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1], vec![2], vec![3, 4]]);
        assert_eq!(p.extended_as_indicator(), vec![0, 0, 1, 2, 2]);
        p.sanity_check();
        Ok(())
    }

    #[test]
    fn test_refine2() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.base_refine_partition_by(&mut tracer, |x| *x % 2 != 0)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.base_refine_partition_by(&mut tracer, |x| *x % 2 != 0)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.base_refine_partition_by(&mut tracer, |x| *x < 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.extended_unsplit_cells_to(2);
        // Do twice, as splitting rearranges internal values
        assert_eq!(p.base_as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.base_refine_partition_by(&mut tracer, |x| *x < 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.extended_unsplit_cells_to(2);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.base_refine_partition_by(&mut tracer, |x| *x >= 2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![1], vec![2, 4], vec![3]]);
        p.sanity_check();
        p.unsplit_cell();
        Ok(())
    }

    #[test]
    fn test_refine_graph() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        let d = Digraph::empty(5);
        p.refine_partition_by_graph(&mut tracer, &d)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        let d2 = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![], vec![]]);
        p.refine_partition_by_graph(&mut tracer, &d2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![3, 4], vec![0, 1, 2]]);
        p.sanity_check();
        // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        let d2 = Digraph::from_vec(vec![vec![1], vec![2], vec![0], vec![], vec![]]);
        p.refine_partition_by_graph(&mut tracer, &d2)?;
        assert_eq!(p.base_as_list_set(), vec![vec![3, 4], vec![0, 1, 2]]);
        p.sanity_check();
        Ok(())
    }

    #[test]
    fn test_perm() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        let mut q = PartitionStack::new(5);
        p.base_refine_partition_by(&mut tracer, |x| *x)?;
        q.base_refine_partition_by(&mut tracer, |x| *x)?;
        assert_eq!(perm_between(&p, &q), Permutation::id());
        Ok(())
    }

    #[test]
    fn test_perm2() -> trace::Result<()> {
        let mut tracer = trace::Tracer::new();
        let mut p = PartitionStack::new(5);
        let mut q = PartitionStack::new(5);
        p.base_refine_partition_by(&mut tracer, |x| 10 - *x)?;
        q.base_refine_partition_by(&mut tracer, |x| *x)?;
        assert_eq!(perm_between(&p, &q), Permutation::from_vec(vec![4, 3, 2, 1, 0]));
        Ok(())
    }

    #[test]
    fn test_extend() {
        let mut p = PartitionStack::new(5);
        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);

        p.extend(2);
        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0, 1, 2, 3, 4], vec![5, 6]]);

        p.extend(1);
        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0, 1, 2, 3, 4], vec![5, 6], vec![7]]);

        p.unsplit_cell();
        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0, 1, 2, 3, 4], vec![5, 6]]);

        p.unsplit_cell();
        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
    }

    #[test]
    fn test_extend_refine() -> trace::Result<()> {
        let mut p = PartitionStack::new(3);
        p.extend(3);

        let mut tracer = trace::Tracer::new();

        p.base_refine_partition_by(&mut tracer, |x| *x)?;

        assert!(p.sanity_check());
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![2], vec![1]]);
        assert_eq!(p.extended_as_list_set(), vec![vec![0], vec![3, 4, 5], vec![2], vec![1]]);

        p.extended_refine_partition_by(&mut tracer, |x| *x)?;
        assert_eq!(p.base_as_list_set(), vec![vec![0], vec![2], vec![1]]);
        assert_eq!(
            p.extended_as_list_set(),
            vec![vec![0], vec![3], vec![2], vec![1], vec![5], vec![4]]
        );

        Ok(())
    }
}
