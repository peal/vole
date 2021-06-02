
# Comments to vole devs:

This aims to be about "what we want", rather than "what we have".

One significant change is 'VoleCon.X' will be "the best refiner for X we know" (so VoleCon.InGroup could be GB_Con.InGroupSimple, for example).

Questions:

* Should all constraints in Vole be in VoleCon, or maybe in some other object (name suggestions?) -- I'm tempted to say elsewhere, to make VoleCon always be the simple/best known implementations.
* Is Vole.Stabilizer (and friends) a good idea?
* I want to drop all the 'number of moved points' everywhere an auto-calculate them (there will be an option to define it if you want/need to).
* We don't want to be running a refiner / generating stab chains for 'SymmetricGroup(50)' and friends, so I plan on making VoleCon.InGroup check things like IsSymmetricGroup and IsAlternatingGroup, and replace them with specialised refiners. Should probably still have a way (for our purposes), of saying "run the refiner I want, don't try and specialise".
* 

# Intro

Vole is a high-performance implementation of Graph Backtracking, a generic framework for solving many problems in permutation groups.

Vole can solve three types of problems (which we will explain more in detail below)

* Given a set of groups, find their intersection
* Given a set of cosets, find a single element from their intersection
* Given a group G,an object O, and an action of G on O, find a canonical element of the orbit of O in G.

One import feature of Vole is how groups and cosets are represented -- they are represented by a list of ``properties''. For example, given a permutation q, group G and a set of integers $S$, some groups Vole can represent are:

* VoleCon.InGroup(G) - $$\{p | p in G\}$$
* VoleCon.Normaliser(G) - $$\{ p | G^p = G\}$$
* VoleCon.SetStab(S) - $$\{p | S^p = S\}$$

Given a permutation q, another group H and another set T, we can represent cosets:

* VoleCon.InCoset(q,G) - $$\{p | p \in qG\}$$
* VoleCon.SetTransport(S,T) -- $$\{p | S^p = T\}$$
* VoleCon.Conjugate(G,H) - $$\{p | G^p = H\}$$

(aside: Technically, these aren't always cosets, for example of $$|S| \neq |T|$$, then there are no permutations which map $$S$$ to $$T$$. To simplify things, whenever we say "coset", assume we mean "coset or empty set")


(Note, this next bit should be somewhere else?)

Full list of refiners we want for first release (G,H = group, q,r = permutation, S,T = set, SS, TT = set of set, St, Tt = set of tuple, D1, D2 = digraphs):

* VoleCon.InGroup(G) - $$\{p | p in G\}$$
* VoleCon.InCoset(q,G) - $$\{p | p \in qG\}$$

Qn: Are these good names?
* VoleCon.Normaliser(G) - $$\{ p | G^p = G\}$$
* VoleCon.Conjugate(G,H) - $$\{p | G^p = H\}$$

* VoleCon.Centraliser(q) - $$\{ p | q^p = q \}$$
* VoleCon.Conjugate(q,r) - $$ \{ p | q^p = r \}$$

Qn: Group centraliser is just mapping all generators to themselves? We should probably still have a contructor for it?

* VoleCon.SetStab(S) - $$\{p | S^p = S\}$$
* VoleCon.SetTransport(S,T) -- $$\{p | S^p = T\}$$

Also Tuple, SetSet, SetTuple, Digraph in both Stab and Transport.

Special group cases:

* VoleCon.InSymmetricGroup(S) - which isn't the same as SetStab, as it fixes all points outside S
* VoleCon.InAlternatingGroup(S)

The main purpose of these is to replace the need to give an explicit size "cheaply"

The upper limit is now just the "largest point" of any refiner, which is the largest moved point for a group or permutation, largest value in a set/tuple/etc, or the number of vertices in a graph.



# Recipes

## Groups

The most important part of Vole's generality is that groups and cosets can be defined and combined in many ways. We will not give a series of examples by showing how to map some standard GAP functions to Vole (each of these functions is already implemented by adding 'Vole.' to its name).

Given permutation groups Gi given as GAP permutation groups by a list of generators

Vole.Intersection(G1,G2,G3) : Find the intersection of G1, G2 and G3.

In general when finding the intersection of groups, we use 'VoleFindGroup', which takes a list of the 'properties' (also known as refiners), and finds the group whose members satisfy all those properties. Here we use the property 'VoleCon.InGroup(x)', which checks a permutation is in the group x.

VoleFindGroup([VoleCon.InGroup(G1), VoleCon.InGroup(G2), VoleCon.InGroup(G3)])

This is already more general than GAP -- internally GAP implementations Intersection(G1,G2,G3) as Intersection(Intersection(G1,G2), G3) (aside: Actually it intersects the smallest two of the tree groups first, but the principle applies), while Vole intersects all three in one step.


Now we will add Si: sets of integers:

Vole.Stabilizer(G1, S1, OnSets)

This can be described as "All elements of G1 which stabilize S1". This is equivalent to intersecting G1 with the stablilizer of S1. This is therefore:

VoleFindGroup([VoleCon.InGroup(G1), VoleCon.SetStab(S1)])

There are many other variants of Stabilizer which are implemented in Vole. OnSetsSets (VoleCon.SetSetStab) and OnSetsTuples (VoleCon.SetTupleStab).

On the other hand, OnTuplesSets isn't implemented -- why? Because "Stabilize a tuple of sets" is equivalent to "stabilize every set in this tuple". Therefore we can implement:

Vole.Stabilizer(G1, TS, OnTuplesSets) as

VoleFindGroup(Concatenation([VoleCon.InGroup(G1)], List(TS, s -> VoleCon.SetStab(s))))

To find the normaliser of a group G2 in another group G1, we use:

Vole.Normaliser(G1, G2)

Similarly to stabilizer, we split this into two parts, we find permutations in G1 and which normalise G2, so:

VoleFindGroup([VoleCon.InGroup(G1), VoleCon.Normalise(S1)])


## Cosets

Cosets are handled similarly to groups. The only difference is we must use the VoleFindElement function, which accepts both groups and cosets (although given a list of groups it will always return the identity).

In GAP, many coset operations are handled with RepresentativeAction, for example to find an element of a group G which maps a set S to a set T we can write:

Vole.RepresentationAction(G,S,T,OnSets)

Which we can write as:

VoleFindElement([VoleCon.InGroup(G), VoleCon.SetTransport(S,T)])

VoleFindElement lets us easily combine requirements. If we wanted to find a permutation which is contained in a group G, normalisers a group H, maps a set S to a set T, and also a set of tuples A to a set of tuples B, we can write:

VoleFindElement([VoleCon.InGroup(G), VoleCon.Normaliser(H), VoleCon.SetTransport(S,T), VoleCon.SetTupleTransport(A,B)])


## Canonical Images

Searching for canonical images works a bit differently to other problems, as here there is one special group, which is the group we look in for the canonical image.

At the moment, canonical images in GAP are provided by the Images package (which can efficiently find the canonical image of a set of integers in a permutation group). There are also a number of packages which can find the canonical image of a graph or digraph in the symmetric group, such as Digraphs and GRAPE.

We can emulate images using:

Vole.CanonicalImage(G, S, OnSets)

Which is equivalent to:

VoleFindCanonical(G, [VoleCon.SetStab(S)]);


Note that VoleFindCanonical returns a record, containing the *permutation* which maps S to it's canonical image (this will always be an element of G), and also the stabilizer of S in G (this is calculated while finding the canonical image).

What does it mean to be a canonical permutation? The canonical permutation will always be in the first group G. Further, given two sets S and T, then if $\exists g \in G. S^g = T$, then given the *canonical permutations* pS for S and pT for T, $S^{pS} = T^{pT}$.

The reason the canonical permutation is returned, rather than the canonical image $S^{pS}$, is that it is easy to calculate the image from the permutation, but very hard to find the permutation from the image.


We can also, given a digraph D, find the canonical image of the graph in the symmetric group by doing

Vole.CanonicalImage(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs)

Which in pure vole becomes:

VoleFindCanonical(SymmetricGroup(DigraphVertices(D)), [VoleCon.DigraphStab(D)])

However, we can also find canonical images in other groups, for example:

VoleFindCanonical(MathieuGroup(24), [VoleCon.DigraphStab(D)])

or the canonical image under a group G of another group H under conjugation:

VoleFindCanonical(G, [VoleCon.Normaliser(H)]);