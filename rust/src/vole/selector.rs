use std::collections::HashMap;
use std::num::Wrapping;

use once_cell::sync::Lazy;
use tracing::info;

use crate::datastructures::hash::QHash;

use super::search::SearchConfig;
use super::state::State;

/// Method of choosing which cell (ignoring cells of size 1) to branch on.
/// All techniques use 'earliest cell' as the final tie-breaking strategy.
#[derive(Clone, Copy, Debug)]
enum Selector {
    /// Smallest cell.
    Smallest,
    /// Largest cell.
    Largest,
    /// First cell.
    First,
    /// Cell with the highest bliss-style refining power.
    MostConnected,
    /// MostConnected, breaking ties by smallest cell. (Default.)
    MostConnectedSmallest,
    /// MostConnected, breaking ties by largest cell.
    MostConnectedLargest,
    /// Smallest cell, breaking ties by MostConnected.
    SmallestMostConnected,
}

impl Selector {
    /// Parse a strategy token. Accepts the same names whether they come
    /// from GAP (`search_config.selector`) or the `VOLE_SELECTOR` env
    /// var. `""`/`"default"` map to the default strategy.
    ///
    ///   smallest                 — Vole legacy default.
    ///   largest
    ///   first
    ///   most-connected           — pure bliss-style score.
    ///   most-connected-smallest  — score, tie-break smallest. (Default.)
    ///   most-connected-largest   — score, tie-break largest.
    ///   smallest-most-connected  — smallest, tie-break score.
    fn from_token(tok: &str) -> Selector {
        match tok.trim().to_ascii_lowercase().as_str() {
            "" | "default" | "most-connected-smallest" | "mostconnectedsmallest" => {
                Selector::MostConnectedSmallest
            }
            "smallest" => Selector::Smallest,
            "largest" => Selector::Largest,
            "first" => Selector::First,
            "most-connected" | "mostconnected" => Selector::MostConnected,
            "most-connected-largest" | "mostconnectedlargest" => Selector::MostConnectedLargest,
            "smallest-most-connected" | "smallestmostconnected" => Selector::SmallestMostConnected,
            other => panic!("unknown selector strategy {:?}", other),
        }
    }
}

/// Env fallback, parsed once. Used only when GAP does not name a
/// selector in the search config, so existing `VOLE_SELECTOR`-driven
/// benchmark scripts keep working.
static SELECTOR_ENV: Lazy<Selector> =
    Lazy::new(|| Selector::from_token(&std::env::var("VOLE_SELECTOR").unwrap_or_default()));

/// Resolve the active strategy: GAP's `search_config.selector` wins;
/// an empty / `"default"` value (or none) falls back to `VOLE_SELECTOR`.
fn resolve_selector(cfg: Option<&str>) -> Selector {
    match cfg {
        Some(s) if !matches!(s.trim().to_ascii_lowercase().as_str(), "" | "default") => {
            Selector::from_token(s)
        }
        _ => *SELECTOR_ENV,
    }
}

/// Bliss-style "refining power" of an individual cell.
///
/// Pick a representative `v` of the cell and group its outgoing
/// neighbour-edges by `(neighbour_cell, edge_colour)`.  Each such
/// group represents one signal that branching on this cell could use
/// to split the neighbour cell.  We count a group only when:
///   * the neighbour cell is non-singleton (singletons cannot split
///     further), and
///   * the count of edges in the group is not equal to the size of
///     the neighbour cell (i.e. the connection to that cell is
///     non-uniform — a uniform connection refines nothing).
///
/// This is the same idea as bliss's `sh_first_max_neighbours`
/// (`graph.cc:2747-2797`), with the simplification that Vole stores
/// in/out direction inside the edge colour, so a single pass over
/// `neighbours(v)` covers both directions.
fn cell_refining_power(state: &State, cell_id: usize) -> i64 {
    let part = state.domain.partition();
    let cell = part.cell(cell_id);
    let rep = cell[0];
    let digraph = state.domain.digraph_stack().digraph();
    let neighbours = digraph.neighbours(rep);

    let mut groups: HashMap<(usize, Wrapping<QHash>), usize> = HashMap::new();
    for (&nbr, &colour) in neighbours {
        let nc = part.cell_of(nbr);
        *groups.entry((nc, colour)).or_insert(0) += 1;
    }

    let mut score: i64 = 0;
    for ((nc, _colour), count) in &groups {
        let len = part.cell(*nc).len();
        if len > 1 && *count != len {
            score += 1;
        }
    }
    score
}

fn find_best_cell<F, T>(state: &State, cells: &[usize], func: F) -> usize
where
    F: Fn(&State, usize) -> T,
    T: Ord,
{
    *cells.iter().min_by_key(|&&value| func(state, value)).unwrap()
}

fn find_first_cell(cells: &[usize]) -> usize {
    cells[0]
}

/// The splittable base cells the selector is allowed to branch on.
///
/// Normally every non-singleton base cell is a candidate. When a
/// `branch_first_threshold` `t` is set (the `Aut(widget)` sub-search),
/// we branch all "real" points `< t` before any auxiliary point `>= t`:
/// while any real cell is still splittable, the candidates are exactly
/// the real splittable cells. This makes the rbase come out as a real
/// prefix (a base for the restricted group) followed by aux points,
/// without changing what group / canonical image the search computes
/// (the domain is still the full extended one).
fn candidate_cells(state: &State) -> Vec<usize> {
    let part = state.domain.partition();
    let threshold = state.domain.branch_first_threshold();
    let real_first = matches!(threshold,
        Some(t) if part.base_cells().iter().any(|&i| part.cell(i).len() > 1 && part.cell(i)[0] < t));
    part.base_cells()
        .iter()
        .copied()
        .filter(|&i| part.cell(i).len() > 1)
        .filter(|&i| !real_first || part.cell(i)[0] < threshold.unwrap())
        .collect()
}

pub fn select_branching_cell(state: &State, search_config: &SearchConfig) -> usize {
    // A refiner may have nominated a specific point during the most
    // recent refinement cycle. Use it only if (a) its cell is a base
    // cell (the default selector also restricts to base_cells, so an
    // extended cell containing auxiliary vertices from a set-of-
    // graphs widget would be an unsafe branch target) and (b) the
    // cell isn't already a singleton.
    //
    // Suppressed entirely when a branch-first threshold is set (the
    // Aut(widget) sub-search): honouring a proposal could branch an aux
    // point before the real points are exhausted, breaking the real-base
    // prefix invariant the shortcut relies on. No refiner used by that
    // sub-search proposes anyway.
    if state.domain.branch_first_threshold().is_none() {
        if let Some(p) = state.domain.proposed_branch_point() {
            let part = state.domain.partition();
            let cell = part.cell_of(p);
            let is_base_cell = part.base_cells().contains(&cell);
            if is_base_cell && part.cell(cell).len() > 1 {
                info!(
                    "Selector consuming refiner proposal: point {:?} -> cell {:?} from {:?}",
                    p,
                    cell,
                    part.extended_as_list_set()
                );
                return cell;
            }
            info!(
            "Refiner proposed point {:?} but its cell {:?} is not a usable branch target (is_base={}, size={}); falling back",
            p,
            cell,
            is_base_cell,
            part.cell(cell).len()
        );
        }
    }

    let cells = candidate_cells(state);

    let choice = resolve_selector(search_config.selector.as_deref());
    let cell = match choice {
        Selector::Smallest => find_best_cell(state, &cells, |s, i| s.domain.partition().cell(i).len() as i64),
        Selector::Largest => find_best_cell(state, &cells, |s, i| -(s.domain.partition().cell(i).len() as i64)),
        Selector::First => find_first_cell(&cells),
        Selector::MostConnected => find_best_cell(state, &cells, |s, i| -cell_refining_power(s, i)),
        Selector::MostConnectedSmallest => find_best_cell(state, &cells, |s, i| {
            (-cell_refining_power(s, i), s.domain.partition().cell(i).len() as i64)
        }),
        Selector::MostConnectedLargest => find_best_cell(state, &cells, |s, i| {
            (-cell_refining_power(s, i), -(s.domain.partition().cell(i).len() as i64))
        }),
        Selector::SmallestMostConnected => find_best_cell(state, &cells, |s, i| {
            (s.domain.partition().cell(i).len() as i64, -cell_refining_power(s, i))
        }),
    };

    // With a branch-first threshold, real and aux points must never share
    // a branch cell — they are kept apart by the snapshot graph's
    // refinement (aux vertices have distinct connectivity). Assert it, so
    // a violated assumption crashes here instead of silently corrupting
    // the real/aux prefix split.
    if let Some(t) = state.domain.branch_first_threshold() {
        let c = state.domain.partition().cell(cell);
        let real = c[0] < t;
        assert!(
            c.iter().all(|&x| (x < t) == real),
            "branch cell mixes base ({}) and aux points: {:?}",
            t,
            c
        );
    }

    info!(
        "Choosing to branch on cell {:?} from {:?}",
        cell,
        state.domain.partition().extended_as_list_set()
    );
    cell
}
