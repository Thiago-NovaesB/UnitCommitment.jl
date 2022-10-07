function build_model(prb::Problem)

    options = prb.options
    prb.model = Model(options.solver)
    JuMP.MOI.set(prb.model, JuMP.MOI.Silent(), true)

    add_variables!(prb)
    add_constraints!(prb)
    objective_function!(prb)
    nothing
end

function rerun_model(prb::Problem)
    model = prb.model

    c = value.(model[:c])
    on = value.(model[:on])
    off = value.(model[:off])
    @constraint(model, model[:c] .== c)
    @constraint(model, model[:on] .== on)
    @constraint(model, model[:off] .== off)
    unset_binary.(model[:c])
    unset_binary.(model[:on])
    unset_binary.(model[:off])

    solve_model(prb)
    nothing
end

function solve_model(prb::Problem)

    optimize!(prb.model)
    nothing
end

function add_variables!(prb::Problem)

    add_generation!(prb)
    add_flow!(prb)
    add_deficit!(prb)
    add_comt!(prb)
    add_turn_on!(prb)
    add_turn_off!(prb)
    add_theta!(prb)
    add_reserve!(prb)
    add_deficit_pos!(prb)
    add_flow_pos!(prb)
    add_generation_pos!(prb)
    add_theta_pos!(prb)
    add_fake_demand!(prb)

    nothing
end

function add_constraints!(prb::Problem)

    add_KCL!(prb)
    add_KVL!(prb)
    add_RAMP!(prb)
    add_COMMIT!(prb)
    add_TIMES!(prb)
    add_KCL_pos!(prb)
    add_KVL_pos!(prb)
    add_RAMP_pos!(prb)
    add_GEN_DEV!(prb)
    add_DUAL_FISHER!(prb)
    nothing
end

function objective_function!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    g = model[:g]
    def = model[:def]

    FO = @expression(model, sum(g[i, t] * data.gen_cost[i] for i in 1:size.gen, t in 1:size.stages) + sum(def[j, t] * data.def_cost[j] for j in 1:size.bus, t in 1:size.stages))
    if options.use_commit
        on = model[:on]
        off = model[:off]
        add_to_expression!(FO, sum(on[i, t] * data.on_cost[i] + off[i, t] * data.off_cost[i] for i in 1:size.gen, t in 1:size.stages))
    end

    if options.use_contingency
        reserve_up = model[:reserve_up]
        reserve_down = model[:reserve_down]
        def_pos = model[:def_pos]
        g_pos = model[:g_pos]
        add_to_expression!(FO, sum(reserve_up[i, t] * data.reserve_up_cost[i] + reserve_down[i, t] * data.reserve_down_cost[i] for i in 1:size.gen, t in 1:size.stages))
        add_to_expression!(FO, sum(def_pos[j, t, k] * data.def_cost[j] for j in 1:size.bus, t in 1:size.stages, k in 1:size.K))
        add_to_expression!(FO, sum(g_pos[i, t, k] * data.gen_cost[i] for i in 1:size.gen, t in 1:size.stages, k in 1:size.K))
    end

    @objective(model, Min, FO)

end