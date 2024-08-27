# GraphBacktracking: A simple but slow implementation of graph backtracking
#
#! @Chapter Equitable Graphs
#!
#!
#!
#! @Section Example Methods
#!
#! This section will describe the methods which can
#! be used to make equitable partitions

#! @Description
#!   Given a partition stack, and a list of graphs,
#!   make the partition equitable.
DeclareOperation("GB_MakeEquitableNone", [IsPartitionStack, IsTracer, IsList]);
DeclareOperation("GB_MakeEquitableWeak", [IsPartitionStack, IsTracer, IsList]);
DeclareOperation("GB_MakeEquitableStrong", [IsPartitionStack, IsTracer, IsList]);
DeclareOperation("GB_MakeEquitableFull", [IsPartitionStack, IsTracer, IsList]);
