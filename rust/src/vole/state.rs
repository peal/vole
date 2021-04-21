use super::{
    backtracking::Backtrack, domain_state::DomainState, refiners::refiner_store::RefinerStore,
    stats::Stats,
};

pub struct State {
    pub domain: DomainState,
    pub refiners: RefinerStore,
    pub stats: Stats,
}

impl Backtrack for State {
    fn save_state(&mut self) {
        self.domain.save_state();
        self.refiners.save_state();
    }

    fn restore_state(&mut self) {
        self.domain.restore_state();
        self.refiners.restore_state();
    }
}
