use super::handle_sols::check_solution;
use super::refiners::Refiner;
use super::solutions::Solutions;
use super::state::State;

use tracing::info;

pub fn select_branching_cell<T: State>(state: &T) -> usize {
    let mut cell = std::usize::MAX;
    let mut cell_size = std::usize::MAX;
    info!("Choosing cell: {:?}", state.partition().as_list_set());
    for i in 0..state.partition().cells() {
        let size = state.partition().cell(i).len();
        if size < cell_size && size > 1 {
            cell = i;
            cell_size = state.partition().cell(i).len();
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
    let cell_num = select_branching_cell(state);
    info!("Partition: {:?}", state.partition().as_list_set());
    info!("Branching on {}", cell_num);
    let mut cell: Vec<usize> = part.cell(cell_num).to_vec();
    cell.sort();

    for c in cell {
        state.save_state();
        let ret = state.refine_partition_cell_by(cell_num, |x| *x == c);
        if let Ok(()) = ret {
            simple_search_recurse(state, sols, refiners);
        }
        state.restore_state();
    }
    info!("Returning");
}

pub fn simple_search<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut Vec<Box<dyn Refiner<T>>>,
) {
    for r in refiners.iter_mut() {
        if r.refine_begin(state).is_err() {
            return;
        }
    }

    simple_search_recurse(state, sols, refiners);
}
