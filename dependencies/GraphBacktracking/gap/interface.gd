#! @Chapter Executing a search
#!
#! @Section The main search interface
#!
#! These three functions are the graph backtracking analogues of the
#! <Package>BacktrackKit</Package> search functions
#! <Ref Func="BTKit_SimpleSearch" BookName="BacktrackKit"/>,
#! <Ref Func="BTKit_SimpleSinglePermSearch" BookName="BacktrackKit"/> and
#! <Ref Func="BTKit_SimpleAllPermSearch" BookName="BacktrackKit"/>, and
#! take the same arguments. Each begins from the ordered partition stack
#! <A>ps</A> (see <Ref Func="PartitionStack" BookName="BacktrackKit"/>)
#! and searches for the permutations that satisfy every refiner in the
#! list <A>conlist</A>. Refiners may be built with the constructors in the
#! <C>GB_Con</C> record (see <Ref Chap="Chapter_Refiners"/>) or with any
#! <Package>BacktrackKit</Package> refiner. The optional final argument
#! <A>conf</A> is a configuration record; the recognised fields are
#! <C>cellSelector</C> (the branch-cell selector) and <C>consolidator</C>
#! (the function used to make the graph stack equitable, see
#! <Ref Chap="Chapter_Equitable_Graphs"/>).

#! @Arguments ps, conlist[, conf]
#! @Returns a permutation group
#! @Description
#!  Returns the group of all permutations that satisfy every refiner in
#!  <A>conlist</A>. This is correct only when that set of permutations is
#!  in fact a group (for example, an intersection of groups, a stabiliser,
#!  or a normaliser); use <Ref Func="GB_SimpleSinglePermSearch"/> when the
#!  solution set is a coset.
DeclareGlobalFunction( "GB_SimpleSearch" );

#! @Arguments ps, conlist[, conf]
#! @Returns a permutation, or <K>fail</K>
#! @Description
#!  Returns a single permutation satisfying every refiner in
#!  <A>conlist</A>, or <K>fail</K> if no such permutation exists. This is
#!  the function to use for coset and transporter problems (group or coset
#!  intersection, conjugacy, and so on).
DeclareGlobalFunction( "GB_SimpleSinglePermSearch" );

#! @Arguments ps, conlist[, conf]
#! @Returns a list of permutations
#! @Description
#!  Returns the complete list of permutations satisfying every refiner in
#!  <A>conlist</A>. This enumerates the whole solution set and is
#!  therefore very slow; it is intended for testing and exploration on
#!  small examples.
DeclareGlobalFunction( "GB_SimpleAllPermSearch" );

#! @Section Inspecting the initial graph stack
#!
#! These functions expose the graph stack that is built before any
#! branching takes place. They are used mainly for testing and for
#! understanding how much a set of refiners deduces <Q>for free</Q>, and
#! are unlikely to be needed in ordinary use.

#! @Arguments ps, conlist
#! @Returns a record
#! @Description
#!  Builds the initial graph stack for <A>conlist</A> and returns a record
#!  with components <C>gens</C> (generators of the automorphism group of
#!  the initial stack, as permutations) and <C>answer</C> (<K>true</K> if
#!  every one of those generators already satisfies <A>conlist</A>, so
#!  that no search is required; <K>false</K> otherwise, in which case the
#!  group is a supergroup of the solutions).
DeclareGlobalFunction( "GB_CheckInitialGroup" );

#! @Arguments ps, conlist
#! @Returns a record
#! @Description
#!  The coset analogue of <Ref Func="GB_CheckInitialGroup"/>. Builds the
#!  initial graph stack down both the left and the right branch and
#!  returns a record with components <C>graph1</C>, <C>graph2</C> (the two
#!  canonically-labelled graph stacks) and <C>equal</C> (whether they
#!  coincide).
DeclareGlobalFunction( "GB_CheckInitialCoset" );

#! @Chapter Refiners
#!
#! @Section The <C>GB_Con</C> record
#!
#! &GraphBacktracking; provides its refiners through the global record
#! <C>GB_Con</C>, in the same spirit as the <C>BTKit_Refiner</C> record of
#! <Package>BacktrackKit</Package>. Each field of <C>GB_Con</C> is a
#! function that constructs a refiner; the resulting refiner can be placed
#! in the <A>conlist</A> argument of the search functions in
#! <Ref Chap="Chapter_Executing_a_search"/>, freely mixed with
#! <Package>BacktrackKit</Package> refiners. For the general notion of a
#! refiner and the constraint it refines for, see
#! <Ref Chap="Refiners" BookName="BacktrackKit"/> and
#! <Ref Chap="Constraints" BookName="BacktrackKit"/>. What is specific to
#! this package is that these refiners may additionally push graphs onto
#! the graph stack, as described in <Ref Chap="Chapter_Introduction"/>.
#!
#! The descriptions below cover the refiners intended for ordinary use.
#! Several of them have a family of experimental variants (used for
#! benchmarking the different graph constructions); those are listed in
#! <Ref Sect="Section_ExperimentalNormalisers"/>.
#!
#! @Section Group and coset refiners
#!
#! <List>
#! <Mark><C>GB_Con.InGroup(<A>G</A>)</C></Mark>
#! <Item>refines for the permutations lying in the group <A>G</A>. Placing
#! two such refiners in a search computes a group intersection.</Item>
#! <Mark><C>GB_Con.InCoset(<A>G</A>, <A>x</A>)</C></Mark>
#! <Item>refines for the permutations lying in the right coset
#! <C><A>G</A> * <A>x</A></C>.</Item>
#! </List>
#!
#! <C>GB_Con.InGroupSimple</C> and <C>GB_Con.InCosetSimple</C> are
#! alternative implementations of the same two constraints that push a
#! different (simpler) set of graphs; they exist for comparison and
#! compute the same answers.
#!
#! @BeginExample
#! gap> LoadPackage("graphbacktracking", false);;
#! gap> G := SymmetricGroup(4);;
#! gap> H := DihedralGroup(IsPermGroup, 8);;
#! gap> GB_SimpleSearch(PartitionStack(4),
#! >          [GB_Con.InGroup(G), GB_Con.InGroup(H)]) = Intersection(G, H);
#! true
#! @EndExample
#!
#! @Section Transporter refiners
#!
#! <List>
#! <Mark><C>GB_Con.PermConjugacy(<A>a</A>, <A>b</A>)</C></Mark>
#! <Item>refines for the permutations <C>p</C> with
#! <C><A>a</A> ^ p = <A>b</A></C>, i.e. that conjugate the permutation
#! <A>a</A> to <A>b</A>.</Item>
#! <Mark><C>GB_Con.TransformationConjugacy(<A>a</A>, <A>b</A>)</C></Mark>
#! <Item>likewise for transformations <A>a</A>, <A>b</A>: refines for the
#! permutations <C>p</C> with <C><A>a</A> ^ p = <A>b</A></C> (conjugation),
#! via the functional digraph of each transformation.</Item>
#! <Mark><C>GB_Con.PartialPermConjugacy(<A>a</A>, <A>b</A>)</C></Mark>
#! <Item>likewise for partial permutations <A>a</A>, <A>b</A>.</Item>
#! <Mark><C>GB_Con.SetDigraphs(<A>setL</A>, <A>setR</A>)</C></Mark>
#! <Item>refines for the permutations mapping the set of digraphs
#! <A>setL</A> to the set of digraphs <A>setR</A> (under
#! <C>OnSetsDigraphs</C>). With <A>setL</A> = <A>setR</A> this is the
#! setwise stabiliser of a set of digraphs.</Item>
#! </List>
#!
#! @Section Normaliser and group-conjugacy refiners
#!
#! These are the refiners that motivate graph backtracking, and the main
#! addition in this release. To compute the normaliser of <A>G</A> inside
#! some group <A>U</A>, combine the normaliser refiner with a
#! <C>BTKit_Refiner.InGroup(<A>U</A>)</C> (or <C>GB_Con.InGroup</C>)
#! refiner.
#!
#! <List>
#! <Mark><C>GB_Con.NormaliserOrbital(<A>G</A>)</C></Mark>
#! <Item>the recommended refiner for the normaliser of <A>G</A>. It pushes
#! the orbital graphs of the relevant stabilisers (encoded as a set of
#! graphs the normaliser may permute), together with orbit colourings and
#! root-level block systems.</Item>
#! <Mark><C>GB_Con.GroupConjugacyOrbital(<A>L</A>, <A>R</A>)</C></Mark>
#! <Item>the transporter version: refines for the permutations conjugating
#! the group <A>L</A> to the group <A>R</A> (group conjugacy under
#! <C>OnPoints</C>). <C>GB_Con.NormaliserOrbital(<A>G</A>)</C> is exactly
#! <C>GB_Con.GroupConjugacyOrbital(<A>G</A>, <A>G</A>)</C>.</Item>
#! </List>
#!
#! @BeginExample
#! gap> G := Group((1,2,3,4,5));;
#! gap> N := GB_SimpleSearch(PartitionStack(5),
#! >          [BTKit_Refiner.InGroup(SymmetricGroup(5)),
#! >           GB_Con.NormaliserOrbital(G)]);;
#! gap> N = Normaliser(SymmetricGroup(5), G);
#! true
#! @EndExample
#!
#! @Section Experimental normaliser variants
#! @SectionLabel ExperimentalNormalisers
#!
#! For experimenting with the different graph constructions, several other
#! normaliser refiners are provided. They all compute the same normaliser
#! as <C>GB_Con.NormaliserOrbital</C> (and the corresponding
#! <C>GroupConjugacy*</C> two-argument forms exist as well), but differ in
#! which graphs and deductions they push, and hence in speed:
#! <C>NormaliserSimple</C>, <C>NormaliserSimple2</C>,
#! <C>NormaliserOrbitalRoot</C>, <C>NormaliserOrbitalNone</C>,
#! <C>NormaliserOrbitalDeep</C>, <C>NormaliserOrbitalSmall</C>,
#! <C>NormaliserOrbitalRegOrbit</C> and
#! <C>NormaliserOrbitalRegOrbitChar</C>. The trade-offs of each are
#! documented in the comments of <F>gap/constraints/normaliser.g</F>.
#!
#! <B>Warning.</B> The two regular-orbit variants
#! (<C>NormaliserOrbitalRegOrbit</C> and
#! <C>NormaliserOrbitalRegOrbitChar</C>) are <E>not</E> canonical-safe:
#! they are correct for testing normaliser/conjugacy equality, but must
#! not be used for canonical-image computations. Use
#! <C>GB_Con.NormaliserOrbital</C> when a canonical image is required.

# From init.g
_BTKit.InitInterfaceGB := true;
