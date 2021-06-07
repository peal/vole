use std::any::Any;

use crate::perm::Permutation;
use crate::vole::backtracking::Backtrack;
use crate::vole::trace;

use super::domain_state::DomainState;

use serde::Serialize;

#[derive(Debug, Serialize, Clone, Copy)]
pub enum Side {
    Left,
    Right,
}

macro_rules! gen_any_image_compare {
    ($name:ty) => {
        fn any_image(&self, p: &Permutation, s: Side) -> Box<dyn std::any::Any> {
            let val: $name = self.image(p, s);
            Box::new(val)
        }

        fn any_compare(
            &self,
            lhs: &Box<dyn std::any::Any>,
            rhs: &Box<dyn std::any::Any>,
        ) -> std::cmp::Ordering {
            let lhs_ref = lhs.downcast_ref::<$name>().unwrap();
            let rhs_ref = rhs.downcast_ref::<$name>().unwrap();
            self.compare(lhs_ref, rhs_ref)
        }

        fn any_to_string(&self, s: &Box<dyn std::any::Any>) -> String {
            let s_ref = s.downcast_ref::<$name>().unwrap();
            format!("{:?}", s_ref)
        }
    };
}

pub trait Refiner: Backtrack {
    /// A human readable name for the refiner
    fn name(&self) -> String;

    /// Check if this refiner represents a group (as opposed to a coset)
    fn is_group(&self) -> bool;

    /// Check is permutation is in group/coset represented by the refiner
    fn check(&self, p: &Permutation) -> bool;

    /// Return image of the internal state under a given permutation.
    /// Refiners will implement an 'image' function, then
    /// use 'gen_any_image_compare!(type)' to generate this function.
    fn any_image(&self, p: &Permutation, _: Side) -> Box<dyn Any>;

    /// Compare two values previously returned by any_image. Refiners
    /// should implement a 'compare' function, and then use
    /// gen_any_image_compare! to create this function.
    fn any_compare(&self, lhs: &Box<dyn Any>, rhs: &Box<dyn Any>) -> std::cmp::Ordering;

    /// Convert a previously return state to a string.
    /// Generated by the 'gen_any_image_compare' macro.
    fn any_to_string(&self, s: &Box<dyn Any>) -> String;

    fn refine_begin(&mut self, _: &mut DomainState, _: Side) -> trace::Result<()> {
        Ok(())
    }

    fn refine_fixed_points(&mut self, _: &mut DomainState, _: Side) -> trace::Result<()> {
        Ok(())
    }

    fn refine_changed_cells(&mut self, _: &mut DomainState, _: Side) -> trace::Result<()> {
        Ok(())
    }

    fn snapshot_rbase(&mut self, _: &mut DomainState) {}
}

pub mod digraph;
pub mod gaprefiner;
pub mod refiner_store;
pub mod simple;
