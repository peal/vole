#@local
gap> START_TEST("settupletrans.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)), IsPermGroup ], function(s,g)
>      local s2, res, p;
>      p := Random(g);
>      s2 := OnSetsTuples(s,p);
>      res := VoleFind.Rep(VoleCon.Transport(s,s2,OnSetsTuples), BTKit_Con.InGroupSimple(g));
>      if res = fail or OnSetsTuples(s,res) <> s2 then
>          return StringFormatted("Failure: {} {} {}", s2, p, OnSetsTuples(s,res));
>      fi;
>      return true;
>  end);
true

#
gap> VoleFind.Rep(4, VoleRefiner.SetTupleTransporter([[]], []));
fail
gap> VoleFind.Rep(4, VoleRefiner.SetTupleTransporter([], [[]]));
fail

#
gap> STOP_TEST("settupletrans.tst");
