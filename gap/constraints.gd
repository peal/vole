# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole constraints


#! @Chapter Constraints
#! @ChapterLabel Constraints


#! @Section Bounds associated with a constraint or refiner
#! @SectionLabel bounds

#! In &GAP;, permutations are defined on the set of all positive
#! integers (although each permutation may move only a finite set of points,
#! and there is a system-dependent maximum point that is allowed to be moved).
#!
#! &Vole; can only search within a concrete finite symmetric group.
#! Therefore, when giving &Vole; a collection of constraints that define a
#! search problem, the search space must be bounded.
#! More specifically, &Vole; must be easily able to deduce a positive integer
#! `k` such that the whole search can take place within `Sym([1..k])`.
#! This guarantees that &Vole; will terminate (given sufficient resources).
#!
#! To help &Vole; make such a deduction, each constraint and refiner
#! is associated with the following values:
#! a **largest moved point**, and a **largest required point**.
#!
#! Any call to <Ref Func="VoleFind.Group"/> or <Ref Func="VoleFind.Coset"/>
#! requires at least one constraint that defines a **finite** largest moved
#! point, and any call to <Ref Func="VoleFind.Representative"/> requires at
#! least one constraint that defines a finite largest required point
#! or a finite largest moved point.
#!
#! <B>Largest moved point</B>
#!
#! The largest **moved** point of a constraint is either <K>infinity</K>,
#! or a positive integer `k` for
#! which it is known a priori that any permutation satisfying the
#! constraint fixes all points strictly greater than `k`.
#!
#! For example, the largest moved point of the constraint
#! `Constraint.InGroup(G)` is `LargestMovedPoint(G)`, see
#! <Ref Attr="LargestMovedPoint" BookName="Ref" Style="Number"
#!      Label="for a list or collection of permutations"/>.
#! On the other hand, any permutation stabilises the empty set, so there is not
#! largest moved point of the constraint `Constraint.Stabilise([],OnSets)`;
#! therefore the value in this case must be <K>infinity</K>.
#!
#! <B>Largest required point</B>
#!
#! The largest **required** point of a constraint is either
#! <K>infinity</K>, or a positive integer `k` such that there exists a
#! permutation satisfying the constraint if and only if there exists a
#! permutation in `Sym([1..k])` satisfying the constraint.
#!
#! For example, if `set` is a set of positive integers, then the largest
#! required point of the constraint `Constraint.Stabilise(set,OnSets)` is
#! `Maximum(set)`.
#!
#! The largest moved point of a constraint can serve as an upper bound for the
#! largest required point of a constraint.
