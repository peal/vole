use crate::state::State;
use crate::refiners::Refiner;

pub fn select_branching_cell<T:State>(state: &T) -> usize {
    let mut cell = std::usize::MAX;
    let mut cellsize = std::usize::MAX;
    for i in 1..state.partition().cells() {
        if state.partition().cell(i).len() < cellsize {
            cell = i;
            cellsize = state.partition().cell(i).len();
        }
    }
    assert_ne!(cell, std::usize::MAX);
    cell
}

pub fn simple_search_recurse<T:State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> trace::Result<()> {
    let part = state.partition();
    let cellnum = select_branching_cell(state);
    let mut cell: Vec<usize> = part.cell(cellnum).iter().cloned().collect();
    cell.sort();

    for c in cell {
        let saved = state.save_state();
        let ret = state.refine_partition_cell_by(cellnum, |x| *x == c);
        if let Ok(()) = ret {
            simple_search_recurse(state, refiners)?;
        }
        state.restore_state(saved);
    }
    Ok(())
}

pub fn simple_search<T:State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> trace::Result<()> {
    for r in refiners.iter_mut() {
        r.refine_begin(state)?;
    }

    simple_search_recurse(state, refiners)?;

    Ok(())
}