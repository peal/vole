use std::ops::{Deref, DerefMut};

pub trait Backtrack {
    fn bt_save(&mut self);
    fn bt_revert(&mut self);
}

pub struct Backtracking<T: Clone> {
    value: T,
    stack: Vec<T>,
}

impl<T: Clone> Backtracking<T> {
    pub fn new(t: T) -> Backtracking<T> {
        Backtracking {
            value: t,
            stack: Vec::new(),
        }
    }
}

impl<T: Clone> Backtrack for Backtracking<T> {
    fn bt_save(&mut self) {
        self.stack.push(self.value.clone());
    }

    fn bt_revert(&mut self) {
        self.value = self.stack.pop().unwrap();
    }
}

impl<T: Clone> Deref for Backtracking<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

impl<T: Clone> DerefMut for Backtracking<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.value
    }
}

pub struct BacktrackingStack<T: Clone> {
    stack: Vec<T>,
    saved_depths: Vec<usize>,
}

impl<T: Clone> BacktrackingStack<T> {
    fn new(t: T) -> BacktrackingStack<T> {
        BacktrackingStack {
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

impl<T: Clone> Backtrack for BacktrackingStack<T> {
    fn bt_save(&mut self) {
        self.saved_depths.push(self.stack.len());
    }

    fn bt_revert(&mut self) {
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
        bt.bt_save();
        assert_eq!(*bt, 3);
        *bt = 4;
        assert_eq!(*bt, 4);
        bt.bt_save();
        assert_eq!(*bt, 4);
        *bt = 5;
        assert_eq!(*bt, 5);
        bt.bt_save();
        assert_eq!(*bt, 5);
        bt.bt_revert();
        assert_eq!(*bt, 5);
        bt.bt_revert();
        assert_eq!(*bt, 4);
        bt.bt_revert();
        assert_eq!(*bt, 3);

        // Check reverting again panics, stop backtrace being printed
        std::panic::set_hook(Box::new(|_info| {}));
        assert!(std::panic::catch_unwind(move || bt.bt_revert()).is_err());
    }

    #[test]
    fn check_backtrackstack() {
        let mut bt = BacktrackingStack::new(2);
        assert_eq!(*bt.get(), vec![2]);
        bt.push(3);
        assert_eq!(*bt.get(), vec![2, 3]);
        bt.bt_save();
        assert_eq!(*bt.get(), vec![2, 3]);
        bt.push(3);
        assert_eq!(*bt.get(), vec![2, 3, 3]);
        bt.push(4);
        bt.push(5);
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.bt_save();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.push(6);
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.bt_save();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.bt_save();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.push(8);
        bt.bt_revert();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.bt_revert();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5, 6]);
        bt.bt_revert();
        assert_eq!(*bt.get(), vec![2, 3, 3, 4, 5]);
        bt.bt_revert();
        assert_eq!(*bt.get(), vec![2, 3]);

        // Check reverting again panics, stop backtrace being printed
        std::panic::set_hook(Box::new(|_info| {}));
        assert!(std::panic::catch_unwind(move || bt.bt_revert()).is_err());
    }
}
