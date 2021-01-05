//#![warn(clippy::pedantic, clippy::nursery)]
// Options to allow if we turn on pedantic options
//#![allow(clippy::doc_markdown,clippy::use_self,clippy::default_trait_access,clippy::missing_errors_doc,clippy::must_use_candidate,clippy::must_use_candidate,clippy::missing_const_for_fn)]

#![allow(dead_code)]
#![allow(clippy::stable_sort_primitive)]
#![allow(clippy::rc_buffer)]
#![warn(clippy::needless_borrow, clippy::use_self)]
pub mod datastructures;
pub mod perm;
pub mod vole;
pub mod gap_chat;

#[macro_use]
extern crate bitflags;

#[macro_use]
extern crate lazy_static;