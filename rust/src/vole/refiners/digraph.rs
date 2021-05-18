use std::sync::Arc;

use super::Refiner;
use super::{super::domain_state::DomainState, Side};
use crate::perm::Permutation;
use crate::vole::trace;
use crate::{datastructures::digraph::Digraph, vole::backtracking::Backtrack};

pub struct DigraphTransporter {
    digraph_left: Arc<Digraph>,
    digraph_right: Arc<Digraph>,
}

impl DigraphTransporter {
    pub fn new_stabilizer(digraph: Arc<Digraph>) -> Self {
        Self::new_transporter(digraph.clone(), digraph)
    }

    pub fn new_transporter(digraph_left: Arc<Digraph>, digraph_right: Arc<Digraph>) -> Self {
        Self {
            digraph_left,
            digraph_right,
        }
    }

    fn image(&self, p: &Permutation, side: Side) -> Digraph {
        let digraph = match side {
            Side::Left => &self.digraph_left,
            Side::Right => &self.digraph_right,
        };
        &(**digraph) ^ p
    }

    fn compare(&self, lhs: &Digraph, rhs: &Digraph) -> std::cmp::Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for DigraphTransporter {
    gen_any_image_compare!(Digraph);

    fn name(&self) -> String {
        if self.is_group() {
            format!("DigraphTransporter of {:?}", self.digraph_left)
        } else {
            format!(
                "DigraphTransporter of {:?} -> {:?}",
                self.digraph_left, self.digraph_right
            )
        }
    }

    fn check(&self, p: &Permutation) -> bool {
        // Old Slower implementation: &(*self.digraph_left) ^ p == *self.digraph_right

        for i in 0..self.digraph_left.vertices() {
            let i_img = p.apply(i);
            let img_neighbours = self.digraph_right.neighbours(i_img);
            for (&target, colour) in self.digraph_left.neighbours(i) {
                if img_neighbours.get(&p.apply(target)) != Some(colour) {
                    return false;
                }
            }
        }
        true
    }

    fn refine_begin(&mut self, state: &mut DomainState, side: Side) -> trace::Result<()> {
        state.add_arc_graph(match side {
            Side::Left => &self.digraph_left,
            Side::Right => &self.digraph_right,
        });

        Ok(())
    }

    fn is_group(&self) -> bool {
        Arc::ptr_eq(&self.digraph_left, &self.digraph_right)
    }
}

impl Backtrack for DigraphTransporter {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
}
