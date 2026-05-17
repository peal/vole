use std::fmt::Debug;

use tracing::info;

use crate::datastructures::hash::QuickHashable;

use super::state::State;

/// Method of choosing which cell (ignoring cells of size 1) to branch on.
/// All techniques use 'earliest cell' as the final tie-breaking strategy
enum Selector {
    /// Smallest cell
    Smallest,
    /// Largest cell
    Largest,
    /// First cell
    First,
    /// Cell where the values are non-trivially connected to the most other cells
    MostConnected,
    /// Smallest cell, breaking ties by choosing MostConnected
    SmallestMostConnected,
}

fn find_best_cell<F: Copy, T: Ord + Debug + QuickHashable>(state: &State, func: F) -> usize
where
    F: Fn(&State, usize) -> T,
{
    *state
        .domain
        .partition()
        .base_cells() // Get cells to branch on
        .iter()
        .filter(|&&i| state.domain.partition().cell(i).len() > 1)
        .min_by_key(|&&value| func(state, value))
        .unwrap()
}

fn find_first_cell(state: &State) -> usize {
    *state
        .domain
        .partition()
        .base_cells() // Get cells to branch on
        .iter()
        .find(|&&i| state.domain.partition().cell(i).len() > 1)
        .unwrap()
}

pub fn select_branching_cell(state: &State) -> usize {
    // A refiner may have nominated a specific point during the most
    // recent refinement cycle. Use it only if (a) its cell is a base
    // cell (the default selector also restricts to base_cells, so an
    // extended cell containing auxiliary vertices from a set-of-
    // graphs widget would be an unsafe branch target) and (b) the
    // cell isn't already a singleton.
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

    let choice = Selector::Smallest;
    let cell = match choice {
        Selector::Smallest => find_best_cell(state, |s, i| s.domain.partition().cell(i).len()),
        Selector::Largest => find_best_cell(state, |s, i| -(s.domain.partition().cell(i).len() as isize)),
        Selector::First => find_first_cell(state),
        _ => unimplemented!(),
    };

    info!(
        "Choosing to branch on cell {:?} from {:?}",
        cell,
        state.domain.partition().extended_as_list_set()
    );
    cell
}
