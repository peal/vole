use crate::handlesols::check_solution;
use crate::refiners::Refiner;
use crate::solutions::Solutions;
use crate::state::State;

use log::trace;

pub fn select_branching_cell<T: State>(state: &T) -> usize {
    let mut cell = std::usize::MAX;
    let mut cellsize = std::usize::MAX;
    trace!("Choosing cell: {:?}", state.partition().as_list_set());
    for i in 0..state.partition().cells() {
        let size = state.partition().cell(i).len();
        if size < cellsize && size > 1 {
            cell = i;
            cellsize = state.partition().cell(i).len();
        }
    }
    assert_ne!(cell, std::usize::MAX);
    cell
}

pub fn simple_search_recurse<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut Vec<Box<dyn Refiner<T>>>,
) {
    let part = state.partition();

    if part.cells() == part.domain_size() {
        if check_solution(state, sols, refiners) {}
        return;
    }
    let cellnum = select_branching_cell(state);
    trace!("Partition: {:?}", state.partition().as_list_set());
    trace!("Branching on {}", cellnum);
    let mut cell: Vec<usize> = part.cell(cellnum).to_vec();
    cell.sort();

    for c in cell {
        let saved = state.save_state();
        let ret = state.refine_partition_cell_by(cellnum, |x| *x == c);
        if let Ok(()) = ret {
            simple_search_recurse(state, sols, refiners);
        }
        state.restore_state(saved);
    }
    trace!("Returning");
}

pub fn simple_search<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut Vec<Box<dyn Refiner<T>>>,
) {
    for r in refiners.iter_mut() {
        if let Err(_) = r.refine_begin(state) {
            return;
        }
    }

    simple_search_recurse(state, sols, refiners);
}
