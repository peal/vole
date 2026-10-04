# Assisted-by: OpenAI Codex (GPT-6), isolated benchmark and verification worker.
LoadPackage("vole", false : OnlyNeeded);
VOLE_MODE := "opt-nobuild";

VoleBenchmarkGroup := gens -> Group(Concatenation(List(gens, PermList), [()]));

VoleBenchmarkWorker := function(inputPath, outputPath)
    local job, spec, G, H, N, ref, start, elapsed, out, expected,
          hasReference, containsChecked, sourceFiles;
    job := JsonStringToGap(StringFile(inputPath));
    spec := job.instance;
    H := VoleBenchmarkGroup(spec.generators);
    if IsBound(spec.ambient_generators) then
        G := VoleBenchmarkGroup(spec.ambient_generators);
    else
        G := SymmetricGroup(spec.degree);
    fi;
    Reset(GlobalMersenneTwister, job.seed);
    if job.operation = "verify" then
        N := VoleBenchmarkGroup(job.result.generators);
        containsChecked := IsSubgroup(G, H);
        out := rec(
            inside_ambient := ForAll(GeneratorsOfGroup(N), p -> p in G),
            normalises_input := ForAll(GeneratorsOfGroup(N), p -> H ^ p = H),
            contains_input_checked := containsChecked,
            contains_input := not containsChecked or IsSubgroup(N, H));
        out.valid_subgroup := out.inside_ambient and out.normalises_input
            and out.contains_input;
        hasReference := IsBound(job.reference);
        out.oracle_available := hasReference;
        if hasReference then
            expected := VoleBenchmarkGroup(job.reference.generators);
            out.order_matches := Size(N) = Size(expected);
            out.equal := N = expected;
        fi;
    else
        _Vole.RootAutShortcut := job.shortcut;
        _Vole.Selector := job.selector;
        # Public-call costs include refiner and characteristic discovery.
        start := NanosecondsSinceEpoch();
        if job.backend = "gap" then
            if IsSubgroup(G, H) then
                N := Normalizer(G, H);
            else
                N := Intersection(Normalizer(SymmetricGroup(spec.degree), H), G);
            fi;
        elif job.backend = "direct" then
            N := Vole.Normalizer(G, H : wrapper := "direct");
        elif job.backend = "by-orbits" then
            N := Vole.Normalizer(G, H : wrapper := "ByOrbits");
        elif StartsWith(job.backend, "refiner:") then
            ref := GB_Con.(Concatenation("Normaliser", job.backend{[9 .. Length(job.backend)]}))(H);
            N := VoleFind.Group(G, ref);
        else
            Error("Unknown benchmark backend: ", job.backend);
        fi;
        elapsed := NanosecondsSinceEpoch() - start;
        if elapsed < 0 then Error("Wall clock moved backwards"); fi;
        out := rec(call_wall_ns := elapsed, order := String(Size(N)),
            input_order := String(Size(H)), ambient_order := String(Size(G)),
            generators := List(GeneratorsOfGroup(N), p -> ListPerm(p, spec.degree)),
            gap_version := GAPInfo.Version,
            vole_version := GAPInfo.PackagesLoaded.vole[2],
            package_versions := List(SortedList(RecNames(GAPInfo.PackagesLoaded)),
                name -> [name, GAPInfo.PackagesLoaded.(name)[2]]));
        sourceFiles := rec(
            regular_orbit := FilenameFunc(StabTreeRegularOrbitData),
            normaliser := FilenameFunc(_BTKit.makeNormaliserRegOrbitDeduction),
            cross := FilenameFunc(_BTKit.makeNormaliserRegOrbitCrossDeduction),
            wrapper := FilenameFunc(Vole.Normalizer),
            orbital_utils := FilenameFunc(_BTKit.getOrbitalListWithOptions),
            comms := FilenameFunc(_Vole.Solve));
        out.loaded_sources := sourceFiles;
        if job.backend <> "gap" and IsBound(_Vole.LastStats) then
            out.search_nodes := _Vole.LastStats.search_nodes;
            out.refiner_calls := _Vole.LastStats.refiner_calls;
            out.stats_scope := "last_search";
        fi;
    fi;
    # Disable GAP's line wrapping: the output is machine-readable JSON.
    ref := OutputTextFile(outputPath, false);
    SetPrintFormattingStatus(ref, false);
    PrintTo(ref, GapToJsonString(out));
    CloseStream(ref);
end;
