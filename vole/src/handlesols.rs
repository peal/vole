use crate::refiners::Refiner;
use crate::state::State;
use log::trace;

pub fn check_solution<T: State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) {
    if !state.has_rbase() {
        trace!("Taking rbase snapshot");
        state.snapshot_rbase();
    }

    let part = state.partition();
    assert!(part.cells() == part.domain_size());

    trace!(
        "AChecking solution: {:?}",
        state.rbase_partition().as_list_set()
    );
    trace!("BChecking solution: {:?}", part.as_list_set());

    let sol = partitionstack::perm_between(&state.rbase_partition(), &part);

    trace!("Checking solution: {:?}", sol);
}
