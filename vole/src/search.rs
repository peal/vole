use crate::state::State;
use std::cell::Cell;
use std::rc::Rc;
use crate::refiners::Refiner;


pub fn simple_search_recurse<T:State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> trace::Result<()> {
    let part = state.partition();

    Ok(())
}

pub fn simple_search<T:State>(state: &mut T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> trace::Result<()> {
    for r in refiners.iter_mut() {
        r.refine_begin(state)?;
    }

    simple_search_recurse(state, refiners);

    Ok(())
}