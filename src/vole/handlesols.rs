use super::refiners::Refiner;
use super::solutions::Solutions;
use super::state::State;
use crate::partitionstack;
use log::trace;

pub fn check_solution<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut Vec<Box<dyn Refiner<T>>>,
) -> bool {
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
        sols.add(&sol);
    } else {
        trace!("Not solution");
    }
    is_sol
}
