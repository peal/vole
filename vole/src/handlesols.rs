use crate::refiners::Refiner;
use crate::state::State;
use log::trace;

pub fn check_solution<T: State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> bool {
    if !state.has_rbase() {
        trace!("Taking rbase snapshot");
        state.snapshot_rbase();
    }

    let part = state.partition();
    assert!(part.cells() == part.domain_size());

    let sol = partitionstack::perm_between(&state.rbase_partition(), &part);

    trace!("Checking solution: {:?}", sol);

    let is_sol = refiners.iter().all(|x| x.check(&sol));
    if is_sol {
        trace!("Found solution");
    }
    is_sol
}
