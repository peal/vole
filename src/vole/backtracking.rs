use core::fmt;
use std::ops::{Deref, DerefMut};

/// Denote objects whose state can be saved and later restored
/// during backtrack search. These saves and reverts are stored in
/// stack
pub trait Backtrack {
    /// Save the current state of the object
    fn save_state(&mut self);
    /// Revert to a previous saved state
    fn restore_state(&mut self);
}

/// A 'smart pointer' which implements [Backtrack]
#[derive(Debug, Clone)]
pub struct Backtracking<T: Clone + fmt::Debug> {
    value: T,
    stack: Vec<T>,
}

impl<T: Clone + fmt::Debug> Backtracking<T> {
    pub fn new(t: T) -> Self {
        Self {
            value: t,
            stack: Vec::new(),
        }
    }
}

impl<T: Clone + fmt::Debug> Backtrack for Backtracking<T> {
    fn save_state(&mut self) {
        self.stack.push(self.value.clone());
    }

    fn restore_state(&mut self) {
        self.value = self.stack.pop().unwrap();
    }
}

impl<T: Clone + fmt::Debug> Deref for Backtracking<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

impl<T: Clone + fmt::Debug> DerefMut for Backtracking<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.value
    }
}

impl<T: Clone + fmt::Debug> Backtracking<T> {
    pub fn saved_depths(&self) -> usize {
        self.stack.len()
    }

    pub fn get_depth(&self, d: usize) -> &T {
        &self.stack[d]
    }
}

/// A stack which implements [Backtrack]
#[derive(Debug, Clone)]
pub struct BacktrackingStack<T: Clone + fmt::Debug> {
    stack: Vec<T>,
    saved_depths: Vec<usize>,
}

impl<T: Clone + fmt::Debug> BacktrackingStack<T> {
    fn new(t: T) -> Self {
        Self {
            stack: vec![t],
            saved_depths: vec![],
        }
    }

    fn push(&mut self, t: T) {
        self.stack.push(t)
    }

    fn get(&self) -> &Vec<T> {
        &self.stack
    }
}

impl<T: Clone + fmt::Debug> Backtrack for BacktrackingStack<T> {
    fn save_state(&mut self) {
        self.saved_depths.push(self.stack.len());
    }

    fn restore_state(&mut self) {
        let depth = self.saved_depths.pop().unwrap();
        self.stack.truncate(depth);
    }
}

#[cfg(test)]
mod tests {
    use crate::vole::backtracking::Backtracking;
    use crate::vole::backtracking::BacktrackingStack;

    use super::Backtrack;

    #[test]
    fn check_backtrack() {
        let mut bt = Backtracking::new(2);
        assert_eq!(*bt, 2);
        *bt = 3;
        assert_eq!(*bt, 3);
        bt.save_state();
        assert_eq!(*bt, 3);
        *bt = 4;
        assert_eq!(*bt, 4);
        bt.save_state();
        assert_eq!(*bt, 4);
        *bt = 5;
        assert_eq!(*bt, 5);
        bt.save_state();
        assert_eq!(*bt, 5);
        bt.restore_state();
        assert_eq!(*bt, 5);
        bt.restore_state();
        assert_eq!(*bt, 4);
        bt.restore_state();
        assert_eq!(*bt, 3);

        // Check reverting again panics, stop backtrace being printed
        std::panic::set_hook(Box::new(|_info| {}));
        assert!(std::panic::catch_unwind(move || bt.restore_state()).is_err());
    }

    #[test]
    fn check_backtrackstack() {
        let mut bt = BacktrackingStack::new(2);
        assert_eq!(*bt.get(), vec![2]);
        bt.push(3);
        assert_eq!(*bt.get(), vec![2, 3]);
        bt.save_state();
        assert_eq!(*bt.get(), vec![2, 3]);
        bt.push(3);
        assert_eq!(*bt.get(), vec![2, 3, 3]);
        bt.push(4);
        bt.push(5);
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.save_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.push(6);
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.save_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.save_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.push(8);
        bt.restore_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.restore_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.restore_state();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.restore_state();
        assert_eq!(*bt.get(), vec![2, 3]);

        // Check reverting again panics, stop backtrace being printed
        std::panic::set_hook(Box::new(|_info| {}));
        assert!(std::panic::catch_unwind(move || bt.restore_state()).is_err());
    }
}
