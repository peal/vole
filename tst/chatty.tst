#@local ps3, ps6, G, p, graph, g1, g2, _orig_shortcut
gap> START_TEST("chatty.tst");
gap> LoadPackage("vole", false);
true

#
gap> # The root-Aut shortcut would skip the main backtrack and suppress
gap> # most refiner callbacks.  This test traces the backtrack callback
gap> # sequence, so we temporarily disable the shortcut.
gap> _orig_shortcut := _Vole.RootAutShortcut;;
gap> _Vole.RootAutShortcut := false;;
gap> G := VoleFind.Group([_BTKit.ChattyRefiner()]: points := 3);; Print("\n");
initialise:1
fixed:2
changed:2
fixed:3
changed:3
rBaseFinished
solutionFound:()
fixed:3
changed:3
solutionFound:(2,3)
fixed:2
changed:2
fixed:3
changed:3
solutionFound:(1,2,3)

gap> _Vole.RootAutShortcut := _orig_shortcut;;
gap> G = SymmetricGroup(3);
true

#
gap> STOP_TEST("chatty.tst");
