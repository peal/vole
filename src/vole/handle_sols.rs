use super::refiners::Refiner;
use super::solutions::Solutions;
use super::state::State;
use crate::vole::partition_stack;
use tracing::info;

pub fn check_solution<T: State>(
    state: &mut T,
    sols: &mut Solutions,
    refiners: &mut Vec<Box<dyn Refiner<T>>>,
) -> bool {
    if !state.has_rbase() {
        info!("Taking rbase snapshot");
        state.snapshot_rbase();
    }

    let part = state.partition();
    assert!(part.cells() == part.domain_size());

    let sol = partition_stack::perm_between(state.rbase_partition(), part);

    info!("Checking solution: {:?}", sol);

    let is_sol = refiners.iter().all(|x| x.check(&sol));
    if is_sol {
        info!("Found solution");
        sols.add(&sol);
    } else {
        info!("Not solution");
    }
    is_sol
}
