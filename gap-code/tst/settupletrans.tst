gap> Read("gap-code/vole-base.g");
gap> LoadPackage("quickcheck", false);;
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)), IsPermGroup ], function(s,g)
>      local s2, max, res, p;
>      max := Maximum(Maximum(Flat(s)), LargestMovedPoint(g));
>      p := Random(g);
>      s2 := OnSetsTuples(s,p);
>      res := VoleSolve(max, true, [con.SetTupleTransport(s,s2), BTKit_Con.InGroupSimple(max, g)]);
>      if IsEmpty(res.sol) or OnSetsTuples(s,res.sol[1]) <> s2 then
>          return StringFormatted("Failure: {} {} {}", s2, p, OnSetsTuples(s,res.sol[1]));
>      fi;
>      return true;
>  end);
true