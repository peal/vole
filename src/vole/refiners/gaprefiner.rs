use serde::{Deserialize, Serialize};

use super::{Refiner, Side};
use crate::{
    datastructures::digraph::Digraph,
    gap_chat::GapChatType,
    perm::Permutation,
    vole::{backtracking::Backtrack, state::State, trace},
};

pub struct GapRefiner {
    gap_id: usize,
}

#[derive(Debug, Deserialize, Serialize)]
struct GapRefinerReturn {
    digraphs: Option<Vec<Digraph>>,
    partition: Option<Vec<usize>>,
}

impl GapRefiner {
    pub fn new(gap_id: usize) -> Self {
        Self { gap_id }
    }

    fn generic_refine(
        &mut self,
        state: &mut State,
        refiner_type: &str,
        side: Side,
    ) -> trace::Result<()> {
        let ret: GapRefinerReturn = GapChatType::send_request(&(
            "refiner",
            &self.gap_id,
            refiner_type,
            side,
            state.partition().as_indicator(),
        ));

        if let Some(part) = ret.partition {
            state.refine_partition_by(|x| part.get(*x).unwrap_or(&usize::MAX))?;
        }

        if let Some(graphs) = ret.digraphs {
            state.add_graphs(&graphs);
        }
        Ok(())
    }
}

impl Refiner for GapRefiner {
    fn name(&self) -> String {
        GapChatType::send_request(&("refiner", &self.gap_id, "name"))
    }

    fn is_group(&self) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "is_group"))
    }

    fn check(&self, p: &Permutation) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "check", p))
    }

    fn refine_begin(&mut self, s: &mut State, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "begin", side)
    }

    fn refine_fixed_points(&mut self, s: &mut State, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "fixed", side)
    }

    fn refine_changed_cells(&mut self, s: &mut State, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "changed", side)
    }
}

impl Backtrack for GapRefiner {
    fn save_state(&mut self) {}

    fn restore_state(&mut self) {}
}
