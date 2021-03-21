use tracing::{info, trace_span};

use crate::vole::solutions::Solutions;
use crate::vole::trace::TracingType;
use crate::vole::{
    backtracking::{Backtrack, Backtracking},
    partition_stack, trace,
};
use crate::vole::{
    refiners::{Refiner, Side},
    stats::Stats,
};
use crate::{gap_chat::GapChatType, perm::Permutation, vole::domain_state::DomainState};

pub struct RefinerStore {
    refiners: Vec<Box<dyn Refiner>>,
    base_fixed_values_considered: Backtracking<usize>,
    cells_considered: Backtracking<usize>,
}

impl RefinerStore {
    pub fn new_from_refiners(refiners: Vec<Box<dyn Refiner>>) -> Self {
        Self {
            refiners,
            base_fixed_values_considered: Backtracking::new(0),
            cells_considered: Backtracking::new(0),
        }
    }

    pub fn init_refine(
        &mut self,
        state: &mut DomainState,
        side: Side,
        stats: &mut Stats,
    ) -> trace::Result<()> {
        let span = trace_span!("init_refine:", side = debug(side));
        let _e = span.enter();
        for r in self.refiners.iter_mut() {
            r.refine_begin(state, side)?;
            stats.refiner_calls += 1;
        }
        self.do_refine(state, side, stats)
    }

    pub fn do_refine(
        &mut self,
        state: &mut DomainState,
        side: Side,
        stats: &mut Stats,
    ) -> trace::Result<()> {
        let span = trace_span!("do_refine");
        let _e = span.enter();
        loop {
            state.refine_graphs()?;

            let fixed_points = state.partition().base_fixed_values().len();
            assert!(fixed_points >= *self.base_fixed_values_considered);
            if fixed_points > *self.base_fixed_values_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_fixed_points(state, side)?;
                    stats.refiner_calls += 1;
                }
            }

            // TODO: Check base_fixed_values_considered and cells_considered are updated

            let cells = state.partition().base_cells().len();
            assert!(cells >= *self.cells_considered);
            if cells > *self.cells_considered {
                for refiner in &mut self.refiners {
                    refiner.refine_changed_cells(state, side)?;
                    stats.refiner_calls += 1;
                }
            }

            if fixed_points == state.partition().base_fixed_values().len()
                && cells == state.partition().base_cells().len()
            {
                // Made no progress
                return Ok(());
            }
        }
    }

    // TODO: This shouldn't be here
    pub fn capture_rbase(&mut self, state: &mut DomainState) {
        assert!(!state.has_rbase());
        state.snapshot_rbase();
    }

    pub fn check_solution(
        &mut self,
        state: &mut DomainState,
        sols: &mut Solutions,
        stats: &mut Stats,
    ) -> bool {
        if !state.has_rbase() {
            info!("Taking rbase snapshot");
            state.snapshot_rbase();
        }

        let part = state.partition();
        let pnts = part.base_domain_size();
        assert!(part.base_cells().len() == pnts);

        let tracing_type = state.tracer().tracing_type();

        let mut is_sol = false;
        if tracing_type.contains(TracingType::SYMMETRY) {
            let sol = partition_stack::perm_between(state.rbase_partition(), part);

            is_sol = self.refiners.iter().all(|x| x.check(&sol));
            if is_sol {
                info!("Found solution: {:?}", sol);
                stats.good_iso += 1;
                sols.add_solution(&sol);
            } else {
                stats.bad_iso += 1;
                info!("Not solution: {:?}", sol);
            }
        }

        if tracing_type.contains(TracingType::CANONICAL) {
            let preimage: Vec<usize> = part.base_cells().iter().map(|&x| part.cell(x)[0]).collect();
            // GAP needs 1 indexed
            let preimagegap: Vec<usize> = preimage.iter().map(|&x| x + 1).collect();
            let postimagegap: Vec<usize> =
                GapChatType::send_request(&("canonicalmin", &preimagegap));
            let postimage: Vec<usize> = postimagegap.into_iter().map(|x| x - 1).collect();
            let mut image: Vec<usize> = vec![0; pnts];
            for i in 0..pnts {
                image[preimage[i]] = postimage[i];
            }
            let perm = Permutation::from_vec(image);
            info!("Considering new canonical image: {:?}", perm);
            stats.bad_canonical += 1;
        }

        is_sol
    }
}

impl Backtrack for RefinerStore {
    fn save_state(&mut self) {
        self.base_fixed_values_considered.save_state();
        self.cells_considered.save_state();
        for c in &mut self.refiners {
            c.save_state();
        }
    }

    fn restore_state(&mut self) {
        self.base_fixed_values_considered.restore_state();
        self.cells_considered.restore_state();
        for c in &mut self.refiners {
            c.restore_state();
        }
    }
}
