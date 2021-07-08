#@local
gap> START_TEST("settupletrans.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)), IsPermGroup ], function(s,g)
>      local s2, max, res, p;
>      max := Maximum(Maximum(Flat(s)), LargestMovedPoint(g),2);
>      p := Random(g);
>      s2 := OnSetsTuples(s,p);
>      res := Vole.FindOne([VoleCon.Transport(s,s2,OnSetsTuples), BTKit_Con.InGroupSimple(max, g)]);
>      if res = fail or OnSetsTuples(s,res) <> s2 then
>          return StringFormatted("Failure: {} {} {}", s2, p, OnSetsTuples(s,res));
>      fi;
>      return true;
>  end);
true

#
gap> STOP_TEST("settupletrans.tst");
