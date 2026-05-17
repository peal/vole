# Known-hang skip list.
#
# Inputs that current Vole.Normalizer is known to hang on (no correctness
# issue, just unacceptably slow with today's refiners). Each entry names
# the phase that should fix it; when that phase lands the entry should be
# removed and the bank re-run to confirm.
#
# Format: each entry is rec(source := "...", key := ..., fixed_by_phase := "C", reason := "...")
# where `source` matches the bank source (e.g. "transgrp") and `key` is
# the per-source identifier (for transgrp: [n, k]).
#
# The bank's sweep functions consult `BankIsKnownHang(source, key)` and
# skip+count those inputs.

BankKnownHangs := [
    # (Empty — TransGrp(11,1) and TransGrp(13,1) were resolved by Phase A's
    # orbital-graph set widget. Add new entries here when a hang is found
    # and recorded for a later phase to address.)
];

# `key` comparison is value equality on lists/ints.
BankIsKnownHang := function(source, key)
    local entry;
    for entry in BankKnownHangs do
        if entry.source = source and entry.key = key then
            return entry;
        fi;
    od;
    return fail;
end;
