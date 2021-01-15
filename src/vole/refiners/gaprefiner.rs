use serde::{Deserialize, Serialize};

use super::Refiner;
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
        side: &str,
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

    fn refine_begin_left(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "begin", "left")
    }

    fn refine_fixed_points_left(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "fixed", "left")
    }

    fn refine_changed_cells_left(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "changed", "left")
    }

    fn refine_begin_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "begin", "right")
    }

    fn refine_fixed_points_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "fixed", "right")
    }

    fn refine_changed_cells_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.generic_refine(s, "changed", "right")
    }
}

impl Backtrack for GapRefiner {
    fn save_state(&mut self) {}

    fn restore_state(&mut self) {}
}
