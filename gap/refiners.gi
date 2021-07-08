


VoleRefiner.SetStab := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetStab := rec(points := s)));
VoleRefiner.TupleStab := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(TupleStab := rec(points := s)));
VoleRefiner.SetSetStab := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetSetStab := rec(points := s)));
VoleRefiner.SetTupleStab := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetTupleStab := rec(points := s)));
VoleRefiner.DigraphStab :=  {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(DigraphStab := rec(edges := _Vole.Digraph(s))));

VoleRefiner.InSymmetricGroup := {s} -> rec(bounds := rec(largest_required_point := _Vole.lmp(s), largest_moved_point := _Vole.lmp(s)), con := rec(InSymmetricGroup := rec(points := s)));

VoleRefiner.SetTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(SetTransport := rec(left_points := s, right_points := t)));
VoleRefiner.TupleTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con :=rec(TupleTransport := rec(left_points := s, right_points := t)));
VoleRefiner.SetSetTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con :=rec(SetSetTransport := rec(left_points := s, right_points := t)));
VoleRefiner.SetTupleTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con :=rec(SetTupleTransport := rec(left_points := s, right_points := t)));
VoleRefiner.DigraphTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(DigraphStab := rec(left_edges := _Vole.Digraph(s), right_edges := _Vole.Digraph(t))));
