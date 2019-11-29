use crate::state::State;
use std::cell::Cell;
use std::rc::Rc;
use crate::refiners::Refiner;


pub fn simple_search_recurse<T:State>(state: &T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> Result<(),()> {
    let part = state.partition();

}

pub fn simple_search<T:State>(state: &T, refiners: &mut Vec<Box<dyn Refiner<T>>>) -> Result<(),()> {
    for r in refiners {
        r.refine_begin(&state)?;
    }

    simple_search_recurse(state, refiners);

    Ok(())
}