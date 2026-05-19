#@local saved_fgr, H, N
##
## Regression test for the full-graph-refine sub-search.
##
## Until this was fixed, enabling `_Vole.FullGraphRefine := true`
## from GAP caused Vole.Normalizer to either return wrong answers on
## small inputs (e.g. (C_3)^2 gave the Klein-4 group of order 4
## instead of the actual normaliser of order 72) or run away on
## moderately larger ones (e.g. (C_5)^2 did not terminate). The
## root cause was that the Rust sub-search inside `sub_full_refine`
## requested `canonicalmin` over the GAP-Vole pipe, which is bound
## to the outer call's `canonicalgroup`; in group-search mode that
## is `false` and the response is identity-sort, producing orbit-
## index labels that are not g-equivariant for the sub-state.
##
## The fix is twofold:
##   (i) Rust handles the trivial canonical-min case locally inside
##       the sub-search, gated by `SearchConfig.canonical_min_trivial`
##       (forced on by `sub_full_refine`); and
##  (ii) a `SubSearchGuard` in `gap_chat.rs` panics if a GAP callback
##       fires during a sub-search at all, catching this and any
##       future similar bugs at the source.
##
gap> START_TEST("full-graph-refine.tst");
gap> LoadPackage("vole", false);;

## Toggle FGR on.
gap> saved_fgr := _Vole.FullGraphRefine;;
gap> _Vole.FullGraphRefine := true;;

## The minimal previously-broken case: two disjoint 3-cycles. Pre-fix
## this returned 4 (wrong) under FGR=true.
gap> H := Group([(1,2,3), (4,5,6)]);;
gap> N := Vole.Normalizer(SymmetricGroup(6), H);;
gap> Size(N) = 72;
true
gap> N = Normalizer(SymmetricGroup(6), H);
true

## A small transitive case to confirm FGR=true also handles the
## non-intransitive path.
gap> H := SymmetricGroup(4);;
gap> Vole.Normalizer(SymmetricGroup(6), H) = Normalizer(SymmetricGroup(6), H);
true

## Restore the default.
gap> _Vole.FullGraphRefine := saved_fgr;;
gap> STOP_TEST("full-graph-refine.tst");
