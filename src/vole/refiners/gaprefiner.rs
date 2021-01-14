use serde::{Deserialize, Serialize};

use super::Refiner;
use crate::{
    datastructures::digraph::Digraph,
    gap_chat::GapChatType,
    perm::Permutation,
    vole::{backtracking::Backtrack, state::State, trace},
};

pub struct GapRefiner {
    gap_id: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct GapRefinerReturn {
    digraphs: Option<Vec<Digraph>>,
    partition: Option<Vec<isize>>,
}

impl GapRefiner {
    fn new(gap_id: String) -> Self {
        Self { gap_id }
    }

    fn generic_refine(
        &mut self,
        s: &mut State,
        refiner_type: &str,
        side: &str,
    ) -> trace::Result<()> {
        let _ret: GapRefinerReturn = GapChatType::send_request(&(
            "refiner",
            &self.gap_id,
            "refine",
            refiner_type,
            side,
            s.partition().as_indicator(),
        ));

        Ok(())
    }
}

impl Refiner for GapRefiner {
    // A human readable name for the refiners
    fn name(&self) -> String {
        GapChatType::send_request(&("refiner", &self.gap_id, "name"))
    }

    /// Check if this refiner represents a group (as opposed to a coset)
    fn is_group(&self) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "is_group"))
    }

    /// Check is [p] is in group/coset represented by the refiner
    fn check(&self, p: &Permutation) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "check", p))
    }

    fn refine_begin_left(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }

    fn refine_fixed_points_left(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }

    fn refine_changed_cells_left(&mut self, _: &mut State) -> trace::Result<()> {
        Ok(())
    }

    fn refine_begin_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.refine_begin_left(s)
    }

    fn refine_fixed_points_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.refine_fixed_points_left(s)
    }

    fn refine_changed_cells_right(&mut self, s: &mut State) -> trace::Result<()> {
        self.refine_changed_cells_left(s)
    }
}

impl Backtrack for GapRefiner {
    fn save_state(&mut self) {}

    fn restore_state(&mut self) {}
}
