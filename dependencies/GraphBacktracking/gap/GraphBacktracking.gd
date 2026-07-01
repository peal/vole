#
# GraphBacktracking
#
# Declarations
#

#! @Chapter Introduction
#!
#! @Section What is &GraphBacktracking;?
#!
#! &GraphBacktracking; implements the graph backtracking algorithm
#! described in the paper <Q>Computing canonical images in permutation
#! groups with Graph Backtracking</Q>, by Christopher Jefferson, Rebecca
#! Waldecker and Wilf A. Wilson
#! (<URL>https://arxiv.org/abs/2209.02534</URL>). Graph backtracking
#! generalises
#! Leon's partition backtrack: instead of refining only an ordered
#! partition of the points, the search also accumulates a stack of
#! vertex- and edge-labelled graphs, which can capture constraints that a
#! partition alone cannot. This makes it possible to solve problems such
#! as normaliser computation and the canonical image of a graph under an
#! arbitrary group.
#!
#! This package builds directly on the <Package>BacktrackKit</Package>
#! package, and reuses its framework essentially unchanged: ordered
#! partition stacks, tracers, constraints, the refiner protocol, and the
#! top-level search loop. Those concepts are documented in the
#! <Package>BacktrackKit</Package> manual and are not repeated here. This
#! manual assumes you are familiar with them, in particular with
#! <Ref Sect="The concept of constraints" BookName="BacktrackKit"/> and
#! <Ref Chap="Refiners" BookName="BacktrackKit"/>, and documents only what
#! &GraphBacktracking; adds on top.
#!
#! @Section Relationship to BacktrackKit and Vole
#!
#! Like <Package>BacktrackKit</Package>, this package exists for
#! <E>learning and exploring</E> the algorithms. Its performance is
#! <E>extremely poor</E> — often orders of magnitude slower than the
#! built-in &GAP; functions for the same task. For a modern,
#! high-performance implementation of graph backtracking, use the
#! <Package>vole</Package> package
#! (<URL>https://github.com/peal/vole</URL>) instead.
#!
#! The one substantive extension to the <Package>BacktrackKit</Package>
#! refiner protocol is that a &GraphBacktracking; refiner may, in addition
#! to splitting cells of the partition, emit <E>graphs</E>. A value
#! returned by a refiner's <C>refine</C> functions (see
#! <Ref Sect="The record refine" BookName="BacktrackKit"/>) may be a
#! record with the components:
#! * <C>graph</C> — a <Package>Digraphs</Package> digraph that is added to
#!   the graph stack; and/or
#! * <C>vertlabels</C> — a list giving an initial colour for each vertex.
#!
#! The graph stack is then made equitable (see
#! <Ref Chap="Chapter_Equitable_Graphs"/>) and contributes to the branching and
#! pruning of the search in the same way the partition does.

#! @Chapter Executing a search
#!
#! @Section Information and diagnostics
#!
#! &GraphBacktracking; reports diagnostic information through the info
#! class <C>InfoGB</C>, which is set equal to the
#! <Package>BacktrackKit</Package> info class
#! <Ref InfoClass="InfoBTKit" BookName="BacktrackKit"/>; raising the level
#! of either (with <C>SetInfoLevel</C>) therefore raises both. Higher
#! levels print progressively more detail about the progress of the
#! search.
InfoGB := InfoBTKit;

# From init.g
_BTKit.FilesInitGB := true;
