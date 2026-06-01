# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Override mechanism: redirect specific GAP backtrack-search entry
# points to their Vole equivalents, so a head-to-head "search vs
# search" benchmark can use the SAME outer-wrapper code path on both
# sides.  Designed for benchmarking, not for changing default
# behaviour — toggles are explicit per call site.

# Internal: save table of original implementations, keyed by the GAP
# global name we replaced.  Lets us restore without re-reading the
# source.
_Vole.OverrideGAP := rec(saved := rec());

# Install `voleImpl` as the new value of the read-only GAP global
# `name`.  The first call for a given name captures the original so
# `Restore` can put it back.  Subsequent installs replace the
# current value; the saved table is not touched.
_Vole.OverrideGAP.Install := function(name, voleImpl)
    if not IsBound(_Vole.OverrideGAP.saved.(name)) then
        _Vole.OverrideGAP.saved.(name) := ValueGlobal(name);
    fi;
    MakeReadWriteGlobal(name);
    UnbindGlobal(name);
    BindGlobal(name, voleImpl);
end;

# Restore the original GAP implementation, if we have one saved.
# No-op if `name` was never installed.
_Vole.OverrideGAP.Restore := function(name)
    if not IsBound(_Vole.OverrideGAP.saved.(name)) then
        return;
    fi;
    MakeReadWriteGlobal(name);
    UnbindGlobal(name);
    BindGlobal(name, _Vole.OverrideGAP.saved.(name));
end;

# Whether a given name is currently overridden.  Looks at the live
# binding so it stays right even if someone installs/restores
# multiple times.
_Vole.OverrideGAP.IsActive := function(name)
    if not IsBound(_Vole.OverrideGAP.saved.(name)) then
        return false;
    fi;
    return not IsIdenticalObj(ValueGlobal(name),
                              _Vole.OverrideGAP.saved.(name));
end;

# ----------------------------------------------------------------
# DoNormalizerPermGroup override
# ----------------------------------------------------------------
#
# GAP's `NormalizerPermGroup` (stbcbckt.gi:2837) dispatches several
# pre-backtrack reductions (orbit-by-orbit, NormalizerViaRadical for
# fitting-free overgroups, G ⊆ E short-circuits, etc.) and then,
# for the cases that need it, lands in `DoNormalizerPermGroup`
# which builds an RBase and runs `PartitionBacktrack`.  The
# override below replaces that bottom layer with Vole.Normalizer,
# so a benchmark that drives `Normalizer(G, E)` exercises the SAME
# outer reductions on both sides and the timing diff is "Vole's
# backtrack vs GAP's backtrack" rather than "Vole's whole pipeline
# vs GAP's whole pipeline".
#
# `Normalizer(Sym(n), U)` takes a different route in: it dispatches
# to `DoNormalizerSA` (gpprmsya.gi:1400), which first reduces via
# `NormalizerParentSA` and then runs the backtrack on the reduced
# parent P -- either through the recursive `Normalizer(P, U)` or, if
# there is no reduction, via TryNextMethod to the generic method.
# Either way that residual backtrack still bottoms out in
# `DoNormalizerPermGroup` (resolved by name), so the hook DOES fire
# here, on the reduced problem.  When `NormalizerParentSA` settles
# the normaliser purely from symmetric-group structure (e.g. a full
# imprimitive wreath), there is no backtrack at all and the hook
# correctly does not fire.  That asymmetry is the whole point: the
# hook pits backtrack against backtrack and leaves GAP's efficient
# non-backtrack reductions in place.  To run Vole end to end instead,
# call Vole.Normalizer directly.
#
# Contract: `DoNormalizerPermGroup(G, E, L, Omega)` returns the
# normaliser N_G(E) acting on Omega.  Vole.Normalizer(G, E) already
# computes this; L (a lower bound on the result) and Omega (the
# point set) are honoured implicitly by Vole's machinery.
_Vole.DoNormalizerPermGroup_VoleImpl := function(G, E, L, Omega)
    return Vole.Normalizer(G, E);
end;

# Sugar: enable/disable the override under a friendly name.
_Vole.OverrideGAP.NormalizerOn := function()
    _Vole.OverrideGAP.Install("DoNormalizerPermGroup",
                              _Vole.DoNormalizerPermGroup_VoleImpl);
end;

_Vole.OverrideGAP.NormalizerOff := function()
    _Vole.OverrideGAP.Restore("DoNormalizerPermGroup");
end;
