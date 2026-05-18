# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: disjoint direct product decomposition (DDPD)


#! @Chapter Disjoint direct product decomposition
#! @ChapterLabel directprod


#! @Section The concept

#! A permutation group $G \leq S_{\Omega}$ acts on each of its orbits
#! $\Omega_1, \dots, \Omega_k$. We say $G$ admits a *disjoint direct product
#! decomposition (DDPD)* if there is a non-trivial partition
#! $\{\Omega_1, \dots, \Omega_k\} = \mathcal{P}_1 \sqcup \dots \sqcup \mathcal{P}_m$
#! of the orbits such that
#! $$G = G|_{\bigcup \mathcal{P}_1} \times G|_{\bigcup \mathcal{P}_2}
#!         \times \dots \times G|_{\bigcup \mathcal{P}_m},$$
#! where $G|_{X}$ denotes the projection of $G$ onto $X$. The *finest*
#! such decomposition is unique (up to ordering of factors), and we
#! call it *the* DDPD of $G$.
#!
#! In the extreme, if $G$ is transitive (one orbit) the DDPD is trivial:
#! $G$ itself is the unique factor. At the other extreme, a direct
#! product of transitive groups on disjoint supports decomposes into
#! its factors.
#!
#! Most intransitive groups arising in practice are not pure direct
#! products: typical examples are subdirect products glueing
#! several transitive factors via shared quotients. The DDPD detects
#! exactly when no such glueing happens.
#!
#! The implementation follows the algorithm of M. S. Chang and
#! C. Jefferson, *Disjoint direct product decompositions of
#! permutation groups*. The algorithm is essentially linear in the
#! size of a strong generating set: build a stabilizer chain whose
#! base concatenates the orbits, then sift each transversal element
#! using only the base points that lie in *later* orbits. Stripped
#! transversal elements that still move points outside their home
#! orbit reveal an inter-orbit tie; union-find on those ties gives
#! the components.


#! @Section The function

#! @Description
#! Returns the disjoint direct product decomposition of the
#! permutation group <A>G</A>, as a list of records — one record
#! per factor — each of the form
#! `rec(base, genset, group)`, where
#! * `base` is a base of strong generators (a list of points,
#!   contained in the supports covered by the factor);
#! * `genset` is a strong generating set for the factor relative to
#!   `base`;
#! * `group` is the factor itself as a permutation group, with its
#!   stabilizer chain precomputed from `base` and `genset`.
#!
#! The returned list has length 1 iff <A>G</A> is directly
#! indecomposable on its orbits (every pair of orbits is glued).
#!
#! Special cases:
#! * If <A>G</A> is trivial, returns a single-entry list with the
#!   trivial group as factor.
#! * If <A>G</A> is transitive (single orbit), returns a single-entry
#!   list with <A>G</A> itself as factor.
#!
#! @Arguments G
#! @Returns A list of records, one per factor of the finest DDPD.
#! @BeginExampleSession
#! gap> # Pure direct product C_3 x C_5 on disjoint orbits.
#! gap> G := Group([ (1,2,3), (4,5,6,7,8) ]);;
#! gap> decomp := Vole.DDPD(G);;
#! gap> Length(decomp);
#! 2
#! gap> List(decomp, d -> Size(d.group));
#! [ 3, 5 ]
#! gap> # A subdirect product glueing two C_3 orbits via a diagonal.
#! gap> H := Group([ (1,2,3)(4,5,6) ]);;
#! gap> decomp := Vole.DDPD(H);;
#! gap> Length(decomp);
#! 1
#! gap> Size(decomp[1].group);
#! 3
#! @EndExampleSession
DeclareGlobalFunction("Vole.DDPD");

#! @Description
#! Convenience predicate: returns <K>true</K> iff <A>G</A> is *not* a
#! direct product on its orbits, i.e. <A>G</A>'s DDPD has a single
#! factor and that factor spans more than one orbit. Equivalent to
#! `Length(Vole.DDPD(<A>G</A>)) = 1 and Length(Orbits(<A>G</A>)) > 1`.
#! @Arguments G
#! @Returns <K>true</K> or <K>false</K>.
DeclareGlobalFunction("Vole.IsDDPDIndecomposable");
