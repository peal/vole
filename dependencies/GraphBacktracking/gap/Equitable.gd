# GraphBacktracking: A simple but slow implementation of graph backtracking
#
#! @Chapter Equitable Graphs
#!
#! @Section Making a partition equitable
#!
#! During search, the partition must be refined with respect to the
#! current graph stack until it is <E>equitable</E>: informally, until no
#! cell can be split by looking at how its points connect to the cells of
#! the partition. &GraphBacktracking; offers several methods of differing
#! strength and cost. A stronger method splits the partition at least as
#! much as a weaker one, prunes the search tree more, but costs more per
#! node. Which one is used is controlled by the <C>consolidator</C> field
#! of the configuration record passed to the search functions (see
#! <Ref Chap="Chapter_Executing_a_search"/>); the default is
#! <Ref Oper="GB_MakeEquitableStrong" Label="for IsPartitionStack, IsTracer, IsList"/>.
#!
#! Each method takes a partition stack <A>ps</A>, a tracer <A>tracer</A>
#! (see <Ref Chap="Ordered tracers" BookName="BacktrackKit"/>), and a list
#! <A>graphs</A> of digraphs. It refines <A>ps</A> in place, recording the
#! splits in <A>tracer</A>, and returns <K>true</K> on success or
#! <K>false</K> if a split contradicted the tracer (a dead branch).

#! @Arguments ps, tracer, graphs
#! @Description
#!   Does nothing and returns <K>true</K>: the partition is left
#!   unchanged. Provided as a baseline (it makes graph backtracking behave
#!   like ordinary backtracking with respect to the graphs).
DeclareOperation("GB_MakeEquitableNone", [IsPartitionStack, IsTracer, IsList]);

#! @Arguments ps, tracer, graphs
#! @Description
#!   Refines <A>ps</A> by repeatedly splitting each cell according to the
#!   multiset of cells reached along out- and in-edges of each graph,
#!   iterating to a fixed point. This is the classical equitable-partition
#!   refinement applied to each graph in turn.
DeclareOperation("GB_MakeEquitableWeak", [IsPartitionStack, IsTracer, IsList]);

#! @Arguments ps, tracer, graphs
#! @Description
#!   A stronger refinement than <Ref Oper="GB_MakeEquitableWeak" Label="for IsPartitionStack, IsTracer, IsList"/>: it
#!   distinguishes points using the combined edge information across all
#!   graphs simultaneously, rather than one graph at a time. This is the
#!   default consolidator.
DeclareOperation("GB_MakeEquitableStrong", [IsPartitionStack, IsTracer, IsList]);

#! @Arguments ps, tracer, graphs
#! @Description
#!   The strongest (and most expensive) refinement: it builds a single
#!   digraph encoding the whole graph stack, computes its automorphism
#!   group and orbits, and splits the partition by those orbits. This can
#!   prune branches the cheaper methods miss, at a substantial cost per
#!   node.
DeclareOperation("GB_MakeEquitableFull", [IsPartitionStack, IsTracer, IsList]);
