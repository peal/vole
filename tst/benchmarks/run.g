# Benchmark driver.
#
# Usage:
#   gap -q -c 'Read("tst/benchmarks/run.g"); RunBenchmarks(); QUIT;'
#
# Output: CSV to stdout and to tst/benchmarks/latest.csv.

LoadPackage("vole", false);
LoadPackage("transgrp", false);
LoadPackage("primgrp", false);

Read("tst/benchmarks/helpers.g");
Read("tst/benchmarks/cyclic-prime.g");
Read("tst/benchmarks/primitive.g");
Read("tst/benchmarks/intransitive.g");

RunBenchmarks := function()
    local out, t0;
    out := OutputTextFile("tst/benchmarks/latest.csv", false);
    SetPrintFormattingStatus(out, false);
    BenchWriteHeader(out);
    t0 := NanosecondsSinceEpoch();

    Print("# cyclic-prime\n");
    RunBenchmarks_cyclic_prime(out);
    Print("# primitive\n");
    RunBenchmarks_primitive(out);
    Print("# intransitive\n");
    RunBenchmarks_intransitive(out);

    Print("Total wall: ",
          Int((NanosecondsSinceEpoch() - t0) / 1000000), " ms\n");
    CloseStream(out);
    Print("CSV written to tst/benchmarks/latest.csv\n");
end;
