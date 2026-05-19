#@local saved_shortcut, H
##
## Regression test for the root Aut shortcut. Toggled by
## `_Vole.RootAutShortcut` (default false; the shortcut is correct
## but not a perf win on all input classes — see the comment in
## gap/internal/comms.gi).
##
## With the shortcut on, Vole.Normalizer skips the partition
## backtrack when every generator of Aut(post-init digraph stack)
## already satisfies the outer refiners' check. The previously-
## broken (C_3)^2 case is the regression target: under the old
## FGR code path it returned a wrong answer of 4; the shortcut
## should return the correct 72.
##
gap> START_TEST("root-aut-shortcut.tst");
gap> LoadPackage("vole", false);;
gap> saved_shortcut := _Vole.RootAutShortcut;;
gap> _Vole.RootAutShortcut := true;;
gap> H := Group([(1,2,3), (4,5,6)]);;
gap> Size(Vole.Normalizer(SymmetricGroup(6), H)) = 72;
true
gap> _Vole.RootAutShortcut := saved_shortcut;;
gap> STOP_TEST("root-aut-shortcut.tst");
