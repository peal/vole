#@local
gap> START_TEST("grpconjtrans.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup], function(g, h)
>      local h2, res, p;
>      p := Random(g);
>      h2 := h^p;
>      res := VoleFind.Rep(VoleCon.Transport(h,h2), BTKit_Con.InGroupSimple(g));
>      if res = fail or h^res <> h2 then
>          return StringFormatted("Failure: {} {} {} {}", g,h,p,h2);
>      fi;
>      return true;
>  end);
true

#
gap> STOP_TEST("grpconjtrans.tst");
