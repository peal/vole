#![allow(dead_code)]

use std::collections::HashSet;
use std::iter::FromIterator;

#[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd, Hash)]
pub struct Split {
    cell: usize,
}

#[derive(Clone, Debug)]
struct MarkStore {
    marks: Vec<usize>,
}

impl MarkStore {
    fn new(n: usize) -> MarkStore {
        MarkStore {
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

pub struct PartitionStack {
    /// Size of partition
    pub size: usize,

    cells: CellData,

    marks: MarkStore,

    splits: Vec<Split>,
}

impl PartitionStack {
    pub fn new(n: usize) -> PartitionStack {
        PartitionStack {
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

    pub fn cell<'a>(&'a self, i: usize) -> &'a [usize] {
        &self.cells.vals[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    pub fn fixed_cells<'a>(&'a self) -> &'a [usize] {
        &self.cells.fixed
    }

    pub fn fixed_vals<'a>(&'a self) -> &'a [usize] {
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
        assert_eq!(self.cells.starts.len(), self.cells.lengths.len());

        let mut starts: HashSet<usize> = HashSet::from_iter(self.cells.starts.iter().cloned());
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

        self.splits.push(Split { cell });

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

        self.marks.setmarks(cell_start, cell_length, unsplit.cell);

        self.cells.lengths[unsplit.cell] += cell_length;
    }

    fn unsplit_cells_to(&mut self, cells: usize) {
        debug_assert!(self.cells() >= cells);
        while self.cells() > cells {
            self.unsplit_cell();
        }
    }

    /// The following methods are highly unsafe, and must be used with care.
    fn mut_cell<'a>(&'a mut self, i: usize) -> &'a mut [usize] {
        &mut self.cells.vals[self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i]]
    }

    fn mut_fix_cell_inverses(&mut self, i: usize) {
        for j in self.cells.starts[i]..self.cells.starts[i] + self.cells.lengths[i] {
            self.cells.invvals[self.cells.vals[j]] = j;
        }
    }

    pub fn refine_partition_cell_by<F:Copy, T: Ord>(&mut self, i: usize, f: F) -> Result<(), ()>
        where F : Fn(&usize) -> T {
        {
            let cell_slice = self.mut_cell(i);
            cell_slice.sort_by_key(f);
        }
        self.mut_fix_cell_inverses(i);
        {
            let cellstart = self.cells.starts[i];
            for p in (1..self.cells.lengths[i]).rev() {
                if f(&self.cells.vals[cellstart + p]) != f(&self.cells.vals[cellstart + p - 1]) {
                    self.split_cell(i, p);
                }
            }
        }
        Ok(())
    }

    pub fn refine_partition_by<F:Copy,T: Ord>(&mut self, f: F) -> Result<(), ()> 
        where F: Fn(&usize) -> T {
        for i in 0..self.cells() {
            self.refine_partition_cell_by(i, f)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::PartitionStack;
    #[test]
    fn it_works() {
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
    fn test_refine() -> Result<(), ()> {
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(|x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        p.sanity_check();
                // Do twice, as splitting rearranges internal values
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(|x| *x == 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 3, 4], vec![2]]);
        p.sanity_check();
        p.refine_partition_by(|x| *x > 2)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 1], vec![2], vec![3, 4]]);
        p.sanity_check();
        Ok(())
    }

    #[test]
    fn test_refine2() -> Result<(), ()> {
        let mut p = PartitionStack::new(5);
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(|x| *x % 2 != 0)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.unsplit_cell();
        p.sanity_check();
        assert_eq!(p.as_list_set(), vec![vec![0, 1, 2, 3, 4]]);
        p.refine_partition_by(|x| *x % 2 != 0)?;
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(|x| *x < 2)?;
        assert_eq!(p.as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.unsplit_cells_to(2);
        // Do twice, as splitting rearranges internal values
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(|x| *x < 2)?;
        assert_eq!(p.as_list_set(), vec![vec![2, 4], vec![3], vec![0], vec![1]]);
        p.sanity_check();
        p.unsplit_cells_to(2);
        assert_eq!(p.as_list_set(), vec![vec![0, 2, 4], vec![1, 3]]);
        p.sanity_check();
        p.refine_partition_by(|x| *x >= 2)?;
        assert_eq!(p.as_list_set(), vec![ vec![0], vec![1],vec![2, 4], vec![3]]);
        p.sanity_check();
        p.unsplit_cell();
        Ok(())
    }
}
