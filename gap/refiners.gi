# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Vole refiners

# In-group refiners
VoleRefiner.InSymmetricGroup := {s} -> rec(
    bounds := rec(
        largest_required_point := _Vole.lmp(s),
        largest_moved_point := _Vole.lmp(s),
    ),
    con := rec(InSymmetricGroup := rec(points := _Vole.points(s))),
);

# Stabilisers
VoleRefiner.PointStab     := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(PointStab := rec(points := [s])));
VoleRefiner.SetStab       := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetStab := rec(points := s)));
VoleRefiner.TupleStab     := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(TupleStab := rec(points := s)));
VoleRefiner.SetSetStab    := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetSetStab := rec(points := s)));
VoleRefiner.SetTupleStab  := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetTupleStab := rec(points := s)));
VoleRefiner.DigraphStab   := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(DigraphStab := rec(edges := _Vole.Digraph(s))));
VoleRefiner.SetDigraphStab := {s} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s)), con := rec(SetDigraphStab := rec(digraphs := List(s, _Vole.Digraph))));

# Transporters
VoleRefiner.PointTransporter    := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(PointTransport    := rec(left_points := [s], right_points := [t])));
VoleRefiner.SetTransporter      := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(SetTransport      := rec(left_points := s, right_points := t)));
VoleRefiner.TupleTransporter    := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(TupleTransport    := rec(left_points := s, right_points := t)));
VoleRefiner.SetSetTransporter   := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(SetSetTransport   := rec(left_points := s, right_points := t)));
VoleRefiner.SetTupleTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(SetTupleTransport := rec(left_points := s, right_points := t)));
VoleRefiner.DigraphTransporter  := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(DigraphTransport  := rec(left_edges := _Vole.Digraph(s), right_edges := _Vole.Digraph(t))));
VoleRefiner.SetDigraphTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_Vole.lmp(s,t)), con := rec(SetDigraphTransport := rec(left_digraphs := List(s, _Vole.Digraph), right_digraphs := List(t, _Vole.Digraph))));
