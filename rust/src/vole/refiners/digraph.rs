use std::sync::Arc;

use super::Refiner;
use super::{super::domain_state::DomainState, Side};
use crate::datastructures::digraph::RawDigraph;
use crate::perm::Permutation;
use crate::vole::trace;
use crate::{datastructures::digraph::Digraph, vole::backtracking::Backtrack};

pub struct DigraphTransporter {
    digraph_left: Arc<Digraph>,
    digraph_right: Arc<Digraph>,
    digraph_raw_left: Arc<RawDigraph>,
    digraph_raw_right: Arc<RawDigraph>,
}

impl DigraphTransporter {
    pub fn new_stabilizer(digraph: Arc<Digraph>) -> Self {
        let raw = Arc::new(digraph.to_raw_unordered());
        Self {
            digraph_left: digraph.clone(),
            digraph_right: digraph,
            digraph_raw_left: raw.clone(),
            digraph_raw_right: raw,
        }
    }

    pub fn new_transporter(digraph_left: Arc<Digraph>, digraph_right: Arc<Digraph>) -> Self {
        let digraph_raw_left = Arc::new(digraph_left.to_raw_unordered());
        let digraph_raw_right = Arc::new(digraph_right.to_raw_unordered());
        Self {
            digraph_left,
            digraph_right,
            digraph_raw_left,
            digraph_raw_right,
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
        // For problems with many graphs (like finding two-closures), this function can takes >50% of runtime, so it
        // is stupidly optimised. We:
        // * Store graphs as vec<vec<>>, for fastest iteration and (binary) searching
        // * Special-case when we (a) map a graph to itself and (b) map a point to itself.
        //   In that case we check after applying permutation if we need to point is mapped to itself.
        for i in 0..self.digraph_left.vertices() {
            let neighbours = &self.digraph_raw_left[i];

            let i_img = p.apply(i);
            let img_neighbours = &self.digraph_raw_right[i_img];

            // Special case when many points are fixed in the permutation
            if std::ptr::eq(img_neighbours, neighbours) {
                for (target, colour) in neighbours {
                    let t_img = p.apply(*target);
                    if t_img != *target {
                        let equal = match img_neighbours.binary_search_by_key(&t_img, |(a, _)| *a) {
                            Ok(x) => img_neighbours[x].1 == *colour,
                            Err(_) => false,
                        };
                        if !equal {
                            return false;
                        }
                    }
                }
            } else {
                for (target, colour) in neighbours {
                    let t_img = p.apply(*target);
                    let equal = match img_neighbours.binary_search_by_key(&t_img, |(a, _)| *a) {
                        Ok(x) => img_neighbours[x].1 == *colour,
                        Err(_) => false,
                    };
                    if !equal {
                        return false;
                    }
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
