# Quick post-hoc analysis of tst/benchmarks/hunt.csv.
# Picks the best vole row per instance, computes ratio against the gap
# row, and emits two ranked lists:
#   * losses: ratios > 2 (we're at least 2x slower than GAP), descending
#   * wins:   ratios < 0.5 (we're at least 2x faster than GAP), ascending
# Plus per-backend stats.
#
# Usage:
#   gap -q -c 'Read("tst/benchmarks/analyse-hunt.g"); QUIT;'

if not IsBoundGlobal("LoadCsvHunt") then
    LoadCsvHunt := function(path)
        local lines, header, rows, line, fields, row, raw;
        raw := StringFile(path);
        if raw = fail then
            Error("Cannot read ", path);
        fi;
        lines := SplitString(raw, "\n");
        rows := [];
        for line in lines do
            if line = "" or StartsWith(line, "#") then continue; fi;
            fields := SplitString(line, ",");
            if Length(fields) < 10 then continue; fi;
            if fields[1] = "category" then continue; fi;
            row := rec(
                category := fields[1],
                name := fields[2],
                n := Int(fields[3]),
                size := fields[4],          # leave as string — possibly large
                backend := fields[5],
                ms := Int(fields[6]),
                nodes := Int(fields[7]),
                refiner_calls := Int(fields[8]),
                eq_gap := fields[9],
                status := fields[10]);
            Add(rows, row);
        od;
        return rows;
    end;
fi;

# Group rows by (category, name). Returns a record per instance with
# fields gap_ms (or fail), and best_vole_ms (or fail), plus details.
_Group := function(rows)
    local groups, row, key, g;
    groups := rec();
    for row in rows do
        if row.status <> "ok" then continue; fi;
        key := Concatenation(row.category, "/", row.name);
        if not IsBound(groups.(key)) then
            groups.(key) := rec(
                category := row.category,
                name := row.name,
                n := row.n,
                gap_ms := fail,
                voles := []);
        fi;
        g := groups.(key);
        if row.backend = "gap" then
            g.gap_ms := row.ms;
        else
            Add(g.voles, rec(backend := row.backend, ms := row.ms));
        fi;
    od;
    return groups;
end;

# Best vole record (smallest ms) for an instance.
_BestVole := function(g)
    local best, v;
    best := fail;
    for v in g.voles do
        if best = fail or v.ms < best.ms then best := v; fi;
    od;
    return best;
end;

Main := function()
    local rows, groups, key, g, best, ratio, losses, wins, e,
          backend_totals, vrow;
    rows := LoadCsvHunt("tst/benchmarks/hunt.csv");
    groups := _Group(rows);

    losses := []; wins := [];

    for key in RecNames(groups) do
        g := groups.(key);
        if g.gap_ms = fail or g.gap_ms = 0 then continue; fi;
        best := _BestVole(g);
        if best = fail then continue; fi;
        # Work in rationals throughout; only Float at print time.
        ratio := best.ms / g.gap_ms;
        e := rec(
            key := key,
            n := g.n,
            gap_ms := g.gap_ms,
            best_backend := best.backend,
            best_ms := best.ms,
            ratio := ratio);
        if ratio > 2 then Add(losses, e); fi;
        if 2 * ratio < 1 then Add(wins, e); fi;
    od;

    SortBy(losses, e -> -e.ratio);
    SortBy(wins,   e -> e.ratio);

    Print("\n=== TOP LOSSES (vole > 2x GAP) ===\n");
    for e in losses do
        Print(e.key, "  n=", e.n,
              "  gap=", e.gap_ms, "ms  best_vole=", e.best_ms, "ms (",
              e.best_backend, ") -> ratio=", Float(e.ratio), "\n");
    od;

    Print("\n=== WINS (vole < 0.5x GAP) ===\n");
    for e in wins do
        Print(e.key, "  n=", e.n,
              "  gap=", e.gap_ms, "ms  best_vole=", e.best_ms, "ms (",
              e.best_backend, ") -> ratio=", Float(e.ratio), "\n");
    od;

    # Per-backend totals (sum of ms, ok cases only).
    backend_totals := rec();
    for vrow in rows do
        if vrow.status <> "ok" then continue; fi;
        if not IsBound(backend_totals.(vrow.backend)) then
            backend_totals.(vrow.backend) := rec(
                count := 0, ms_sum := 0, ms_max := 0, instance_max := "");
        fi;
        backend_totals.(vrow.backend).count :=
            backend_totals.(vrow.backend).count + 1;
        backend_totals.(vrow.backend).ms_sum :=
            backend_totals.(vrow.backend).ms_sum + vrow.ms;
        if vrow.ms > backend_totals.(vrow.backend).ms_max then
            backend_totals.(vrow.backend).ms_max := vrow.ms;
            backend_totals.(vrow.backend).instance_max := Concatenation(
                vrow.category, "/", vrow.name);
        fi;
    od;
    Print("\n=== PER-BACKEND TOTALS ===\n");
    for key in RecNames(backend_totals) do
        e := backend_totals.(key);
        Print(key, "  count=", e.count, "  total=", e.ms_sum,
              "ms  max=", e.ms_max, "ms @ ", e.instance_max, "\n");
    od;
end;

Main();
