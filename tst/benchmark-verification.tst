# Assisted-by: OpenAI Codex (GPT-6), exact benchmark verification regressions.
gap> START_TEST("benchmark-verification.tst");
gap> ReadPackage("vole", "tst/benchmarks/hunt.g");
true

# Equal orders are insufficient, and an unavailable oracle is unknown.
gap> _HuntCompareResult([(1,2)], [(3,4)]);
false
gap> _HuntCompareResult([(1,2,3)], [(1,3,2)]);
true
gap> _HuntCompareResult(fail, [(1,2)]);
fail
gap> _HuntCompareResult([], [()]);
true
gap> STOP_TEST("benchmark-verification.tst");
