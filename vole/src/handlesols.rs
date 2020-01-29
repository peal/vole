use crate::refiners::Refiner;
use crate::state::State;

use log::trace;

pub fn check_solution<T: State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) {
    let part = state.partition();
    assert!(part.cells() == part.domain_size());
    if !state.has_rbase() {
        trace!("Taking rbase snapshot");
        state.snapshot_rbase();
    }

//    let rbasepart = state.rbase_partition().
    trace!("Checking solution: {:?}", state.partition().as_list_set());
}