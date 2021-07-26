use std::{collections::HashSet, num::Wrapping};

use serde::{Deserialize, Serialize};
use tracing::info;

use super::{Refiner, Side};
use crate::{
    datastructures::{
        digraph::Digraph,
        hash::{do_hash, QHash},
    },
    gap_chat::{GapChatType, GapRef},
    perm::Permutation,
    vole::{
        backtracking::{Backtrack, Backtracking},
        domain_state::DomainState,
        trace,
    },
};

pub struct GapRefiner {
    gap_id: usize,
    seen_results: Backtracking<HashSet<Wrapping<QHash>>>,
}

#[derive(Debug, Deserialize, Serialize, Hash)]
struct GapRefinerGraph {
    graph: Option<Vec<Vec<usize>>>,
    vertlabels: Option<Vec<usize>>,
}

#[derive(Debug, Deserialize, Serialize, Hash)]
struct GapRefinerFailed {
    failed: bool,
}

#[derive(Debug, Deserialize, Serialize, Hash)]
#[serde(untagged)]
enum GapRefinerReturn {
    Graph(GapRefinerGraph),
    Failed(GapRefinerFailed),
}

impl GapRefiner {
    fn extend_part(part: &[usize], max_val: usize, base_size: usize, extended_start: usize) -> Vec<usize> {
        // Points we have to move
        let extra_points = max_val - base_size;
        let mut new_vertlabels = vec![usize::MAX; extended_start + extra_points];

        for (i, label) in new_vertlabels[0..base_size].iter_mut().enumerate() {
            *label = *part.get(i).unwrap_or(&usize::MAX);
        }
        for i in 0..extra_points {
            new_vertlabels[i + extended_start] = *part.get(i + base_size).unwrap_or(&usize::MAX);
        }
        new_vertlabels
    }

    fn extend_digraph(digraph: &Digraph, max_val: usize, base_size: usize, extended_start: usize) -> Digraph {
        // Points we have to move
        let base_verts = 0..base_size;
        let more_verts = extended_start..(extended_start + (max_val - base_size));
        let v = base_verts.chain(more_verts).collect::<Vec<usize>>();
        let mut d_clone = digraph.clone();
        d_clone.remap_vertices(&v);
        d_clone
    }

    pub fn new(gap_id: usize) -> Self {
        Self {
            gap_id,
            seen_results: Backtracking::new(HashSet::new()),
        }
    }

    fn generic_refine(&mut self, state: &mut DomainState, refiner_type: &str, side: Side) -> trace::Result<()> {
        let ret_list: Vec<GapRefinerReturn> = GapChatType::send_request(&(
            "refiner",
            &self.gap_id,
            refiner_type,
            side,
            state.partition().base_as_indicator(),
        ))
        .unwrap();

        let mut keep: Vec<GapRefinerGraph> = vec![];

        for gap_ret in ret_list {
            match gap_ret {
                GapRefinerReturn::Failed(gapfailed) => {
                    // failed should always be true here
                    assert!(gapfailed.failed);
                    // GAP caused search to fail
                    return Err(trace::TraceFailure {});
                }
                GapRefinerReturn::Graph(mut ret) => {
                    // Normalise graph, so hash will return same value
                    if let Some(graph) = &mut ret.graph {
                        for neighbour in graph {
                            neighbour.sort();
                        }
                    }

                    let hash = do_hash(&ret);
                    info!("Run GAP refiner - recieved hash {:?}", hash);
                    /* Have to accept all graphs (for now), as we graphs can have ordering of
                       the extra vertices, while being "the same"
                    if !self.seen_results.contains(&hash) {
                        info!("Found new graph");
                        keep.push(ret);
                    } else {
                        info!("Seen before");
                    }
                    self.seen_results.insert(hash);
                    */
                    keep.push(ret);
                }
            }
        }

        for ret in keep {
            let mut max_val = state.partition().base_domain_size();

            if let Some(part) = &ret.vertlabels {
                max_val = max_val.max(part.len());
            }

            if let Some(graph) = &ret.graph {
                max_val = max_val.max(graph.len());
            }

            let base_size = state.partition().base_domain_size();
            let extended_size = state.partition().extended_domain_size();

            let mut vertlabels = ret.vertlabels;
            let mut digraph = ret.graph.map(Digraph::from_one_indexed_vec);

            if max_val > base_size {
                // First, update partition
                let extra_points = max_val - base_size;
                info!("Sent info from GAP with {:?} extra points", extra_points);
                state.extend_partition(extra_points);

                if let Some(part) = vertlabels {
                    vertlabels = Some(Self::extend_part(&part, max_val, base_size, extended_size));
                }

                if let Some(raw_digraph) = digraph {
                    digraph = Some(Self::extend_digraph(&raw_digraph, max_val, base_size, extended_size));
                };
            }

            if let Some(part) = vertlabels {
                info!("Refining Partition by {:?}", part);
                state.extended_refine_partition_by(|x| part.get(*x).unwrap_or(&usize::MAX))?;
            }

            if let Some(graphs) = digraph {
                state.add_graph(&graphs);
            }
        }
        Ok(())
    }

    fn image(&self, p: &Permutation, side: Side) -> GapRef {
        GapChatType::send_request(&("refiner", &self.gap_id, "image", side, p)).unwrap()
    }

    fn compare(&self, lhs: &GapRef, rhs: &GapRef) -> std::cmp::Ordering {
        let ret: isize = GapChatType::send_request(&("refiner", &self.gap_id, "compare", lhs, rhs)).unwrap();
        match ret {
            -1 => std::cmp::Ordering::Less,
            0 => std::cmp::Ordering::Equal,
            1 => std::cmp::Ordering::Greater,
            _ => panic!(),
        }
    }
}

impl Refiner for GapRefiner {
    gen_any_image_compare!(GapRef);

    fn name(&self) -> String {
        GapChatType::send_request(&("refiner", &self.gap_id, "name")).unwrap()
    }

    fn is_group(&self) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "is_group")).unwrap()
    }

    fn check(&self, p: &Permutation) -> bool {
        GapChatType::send_request(&("refiner", &self.gap_id, "check", p)).unwrap()
    }

    fn refine_begin(&mut self, s: &mut DomainState, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "begin", side)
    }

    fn refine_fixed_points(&mut self, s: &mut DomainState, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "fixed", side)
    }

    fn refine_changed_cells(&mut self, s: &mut DomainState, side: Side) -> trace::Result<()> {
        self.generic_refine(s, "changed", side)
    }

    fn snapshot_rbase(&mut self, s: &mut DomainState) {
        // The 'Side' is not used here
        self.generic_refine(s, "rBaseFinished", Side::Left)
            .expect("Internal Error: GAP RBase Snapshot failure");
    }
}

impl Backtrack for GapRefiner {
    fn save_state(&mut self) {
        let _: bool = GapChatType::send_request(&("refiner", &self.gap_id, "save_state")).unwrap();
    }

    fn restore_state(&mut self) {
        let _: bool = GapChatType::send_request(&("refiner", &self.gap_id, "restore_state")).unwrap();
    }

    fn state_depth(&self) -> usize {
        0
    }
}
