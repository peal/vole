#
# BacktrackKit: An extensible, easy to understand backtracking framework
#


#! @Chapter Executing a search


#! @Section The main search interface

#! Search for generators of a group
DeclareGlobalFunction( "BTKit_SimpleSearch" );

#! Search for a single permutation
DeclareGlobalFunction( "BTKit_SimpleSinglePermSearch" );

#! Search for all permutations (very slow)
DeclareGlobalFunction( "BTKit_SimpleAllPermSearch" );

# Used in init.g
_BTKit.CheckInitgInterface := true;
