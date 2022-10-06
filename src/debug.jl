using JuMP
using Xpress, XpressPSR
XpressPSR.initialize()

model = prb.model

MOI.compute_conflict!(model.moi_backend.optimizer.model)
function query_all_c_refs(model)
    c_refs = []
    list_of_cons = list_of_constraint_types(model)
    for (F, S) in list_of_cons
        push!(c_refs, all_constraints(model, F, S)...)
    end
    return c_refs
end

function list_conflicted_c_refs(model)
    c_refs = query_all_c_refs(model)
    c_refs_in_iis = []
    for c_ref in c_refs
        if MOI.get(model, MOI.ConstraintConflictStatus(), c_ref)
            push!(c_refs_in_iis, c_ref)
        end
    end
    return c_refs_in_iis
end

a = list_conflicted_c_refs(model)