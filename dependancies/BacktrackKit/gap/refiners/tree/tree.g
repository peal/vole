
# TODO: FIX

# BTKit_Refiner.List := function(n, l)
#     local conlist, name, r;
#     conlist := l;

#     name := Concatenation("List(", List(conlist, {c} -> c.name), ")");
#     r := rec(
#         name := name,
#         check := {p} -> ForAll(conlist, {c} -> Check(c!.constraint)(p)),
#         refine := rec(
#             initialise := function(ps, rbase)
#                 local refines, gather;
#                 refines := List(conlist, {c} -> c!.initialise(ps, rbase));
#                 gather := List([1..PS_Points(ps)], {i} -> List([1..Length(refines)], {x} -> refines[i](x)));
#                 return {i} -> gather[i];
#             end,
#             changed := function(ps, rbase)
#                 local refines, gather;
#                 refines := List(conlist, {c} -> c.changed(ps, rbase));
#                 gather := List([1..PS_Points(ps)], {i} -> List([1..Length(refines)], {x} -> refines[i](x)));
#                 return {i} -> gather[i];
#             end)
#     );
#     return r;
# end;

# BTKit_Refiner.Set := function(n, l)
#     local conlist, name, r;
#     conlist := l;

#     name := Concatenation("Set(", List(conlist, {c} -> c.name), ")");
#     r := rec(
#         name := name,
#         check := {p} -> ForAll(conlist, {c} -> Check(c!.constraint)(p)),
#         refine := rec(
#             initialise := function(ps, rbase)
#                 local refines, gather;
#                 refines := List(conlist, {c} -> c!.initialise(ps, rbase));
#                 gather := List([1..PS_Points(ps)], {i} -> List([1..Length(refines)], {x} -> refines[i](x)));
#                 return {i} -> gather[i];
#             end,
#             changed := function(ps, rbase)
#                 local refines, gather;
#                 refines := List(conlist, {c} -> c.changed(ps, rbase));
#                 gather := List([1..PS_Points(ps)], {i} -> List([1..Length(refines)], {x} -> refines[i](x)));
#                 return {i} -> gather[i];
#             end)
#     );
#     return r;
# end;

