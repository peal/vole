use super::Refiner;

use super::{super::domain_state::DomainState, Side};
use crate::{datastructures::sortedvec::SortedVec, vole::trace};
use crate::{perm::Permutation, vole::backtracking::Backtrack};
use std::{cmp::Ordering, rc::Rc};

/// Refine which represents the symmetric group on `set`
pub struct InSymmetricGrp {
    set: Rc<SortedVec<usize>>,
}

impl InSymmetricGrp {
    pub fn new_symmetric_group(set: SortedVec<usize>) -> Self {
        Self { set: Rc::new(set) }
    }

    fn image(&self, p: &Permutation, _: Side) -> SortedVec<usize> {
        self.set.iter().map(|&x| p.apply(x)).collect()
    }

    fn compare(&self, lhs: &SortedVec<usize>, rhs: &SortedVec<usize>) -> Ordering {
        lhs.cmp(rhs)
    }
}

impl Refiner for InSymmetricGrp {
    gen_any_image_compare!(SortedVec<usize>);

    fn name(&self) -> String {
        format!("Symmetric Group on {:?}", self.set)
    }

    fn check(&self, p: &Permutation) -> bool {
        if let Some(lmp) = p.lmp() {
            for i in 0..=lmp {
                if self.set.contains(&i) {
                    if !self.set.contains(&p.apply(i)) {
                        return false;
                    }
                } else {
                    // If p^i = i, then p^i can't be in set.
                    if p.apply(i) != i {
                        return false;
                    }
                }
            }
        }
        true
    }

    fn refine_begin(&mut self, state: &mut DomainState, _: Side) -> trace::Result<()> {
        // x+1 just because we want '0' as a special value
        state.base_refine_partition_by(|x| if self.set.contains(x) { 0 } else { x + 1 })?;
        Ok(())
    }

    fn is_group(&self) -> bool {
        true
    }
}

impl Backtrack for InSymmetricGrp {
    fn save_state(&mut self) {}
    fn restore_state(&mut self) {}
    fn state_depth(&self) -> usize {
        0
    }
}
