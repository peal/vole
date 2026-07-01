#@local boom
gap> START_TEST("daemon.tst");

#
# Daemon mode keeps one vole process alive between searches and reuses it.
# _Vole.daemon caches the live pipe; _Vole.inflight holds the pipe of a search
# in progress (cleared on clean completion, left set if a call escapes).
#
gap> LoadPackage("vole", false);;
gap> _Vole.UseDaemon;
true

#
# StopDaemon lifecycle.
#
gap> _Vole.StopDaemon();;
gap> _Vole.daemon;
fail

# A search leaves a live daemon cached for reuse; nothing left in flight.
gap> Size(VoleFind.Group([VoleRefiner.SetStab([1, 2, 3]), SymmetricGroup(6)]));
36
gap> _Vole.daemon <> fail;
true
gap> _Vole.inflight;
fail

# StopDaemon tears the daemon down; both slots clear.
gap> _Vole.StopDaemon();;
gap> [_Vole.daemon, _Vole.inflight];
[ fail, fail ]

# StopDaemon is idempotent: stopping again when nothing runs is a no-op.
gap> _Vole.StopDaemon();;
gap> _Vole.daemon;
fail

# A search after a stop spawns a fresh daemon and still answers correctly.
gap> Size(VoleFind.Group([VoleRefiner.SetStab([1, 2, 3]), SymmetricGroup(6)]));
36
gap> _Vole.daemon <> fail;
true

#
# Recovery: a GAP refiner callback that crashes mid-search leaves the vole
# process parked (inflight set). The next call must notice, warn, reap it,
# fork a fresh vole, and still answer correctly -- rather than wedging the
# session. This simulates a user hitting an error inside vole and quitting
# the break loop.
#
gap> SetInfoLevel(InfoVole, 1);;
gap> boom := Objectify(BTKitRefinerType, rec(
>          name := "Boom",
>          largest_required_point := 3,
>          constraint := Constraint.Stabilise([1, 2, 3], OnSets),
>          refine := rec(
>              initialise := function(ps, l) Error("boom from refiner callback"); end)));;
gap> VoleFind.Group([boom, SymmetricGroup(6)]);
Error, boom from refiner callback
gap> _Vole.inflight <> fail;
true

# The next search reaps the crashed process (with a warning) and recovers.
gap> Size(VoleFind.Group([VoleRefiner.SetStab([1, 2, 3]), SymmetricGroup(6)]));
#I  Previous vole call didn't exit cleanly, restarting vole
36
gap> _Vole.inflight;
fail
gap> SetInfoLevel(InfoVole, 0);;
gap> _Vole.StopDaemon();;

#
gap> STOP_TEST("daemon.tst");
