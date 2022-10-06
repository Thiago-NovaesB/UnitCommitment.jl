function add_KCL!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    g = model[:g]
    f = model[:f]
    def = model[:def]
    fake_demand = model[:fake_demand]

    @constraint(model, KCL[i in 1:size.bus, t in 1:size.stages], sum(g[j, t] for j in 1:size.gen if data.gen2bus[j] == i) + sum(f[j, t] * data.A[i, j] for j in 1:size.circ) + def[i, t] == fake_demand[i, t])
end

function add_KVL!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_kirchhoff
        f = model[:f]
        theta = model[:theta]
        @constraint(model, KVL[i in 1:size.circ, t in 1:size.stages], f[i, t] == sum(theta[j, t] * data.A[j, i] for j in 1:size.bus) / data.x[i])
    end
end

function add_RAMP!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_ramp && options.use_commit
        g = model[:g]
        c = model[:c]
        on = model[:on]
        off = model[:off]
        @constraint(model, RAMP_UP_0[i in 1:size.gen] , on[i,1]*data.startup[i] + data.ramp_up[i]*data.ISC[i] >= g[i,1] - data.ISP[i])
        @constraint(model, RAMP_UP[t in 1:size.stages-1, i in 1:size.gen] , on[i,t+1]*data.startup[i] + data.ramp_up[i]*c[i,t] >= g[i,t+1] - g[i,t])
        @constraint(model, RAMP_DOWN_0[i in 1:size.gen], -data.ramp_down[i]*data.ISC[i] -off[i,1]*data.shutdown[i] <= g[i,1] - data.ISP[i])
        @constraint(model, RAMP_DOWN[t in 1:size.stages-1, i in 1:size.gen], -data.ramp_down[i]*c[i,t+1] -off[i,t+1]*data.shutdown[i] <= g[i,t+1] - g[i,t])
    elseif options.use_ramp
        g = model[:g]
        @constraint(model, RAMP_UP_0[i in 1:size.gen], data.ramp_up[i] >= g[i, 1] - data.ISP[i])
        @constraint(model, RAMP_UP[t in 1:size.stages-1, i in 1:size.gen], data.ramp_up[i] >= g[i, t+1] - g[i, t])
        @constraint(model, RAMP_DOWN_0[i in 1:size.gen], -data.ramp_down[i] <= g[i, 1] - data.ISP[i])
        @constraint(model, RAMP_DOWN[t in 1:size.stages-1, i in 1:size.gen], -data.ramp_down[i] <= g[i, t+1] - g[i, t])
    end

end

function add_COMMIT!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_commit
        g = model[:g]
        c = model[:c]
        on = model[:on]
        off = model[:off]
        @constraint(model, COMMIT_UP[i in 1:size.gen, t in 1:size.stages], data.g_max[i] * c[i, t] >= g[i, t])
        @constraint(model, COMMIT_DOWN[i in 1:size.gen, t in 1:size.stages], g[i,t] >= data.g_min[i] * c[i,t])

        @constraint(model, STA_COMMIT_CONST_0[i in 1:size.gen], on[i, 1] - off[i, 1] == c[i, 1] - data.ISC[i])
        @constraint(model, STA_on_0[i in 1:size.gen], on[i, 1] + off[i, 1] <= c[i, 1] + data.ISC[i])
        @constraint(model, STA_off_0[i in 1:size.gen], on[i, 1] + off[i, 1] + c[i, 1] + data.ISC[i] <= 2)

        @constraint(model, STA_COMMIT_CONST[i in 1:size.gen, t in 1:size.stages-1], on[i, t+1] - off[i, t+1] == c[i, t+1] - c[i, t])
        @constraint(model, STA_on[i in 1:size.gen, t in 1:size.stages-1], on[i, t+1] + off[i, t+1] <= c[i, t+1] + c[i, t])
        @constraint(model, STA_off[i in 1:size.gen, t in 1:size.stages-1], on[i, t+1] + off[i, t+1] + c[i, t+1] + c[i, t] <= 2)
    end
end

function add_TIMES!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_commit && options.use_up_down_time
        c = model[:c]
        on = model[:on]
        off = model[:off]
        past(i, t) = (data.IST[i] > 0 && data.IST[i] + t - data.up_time[i] <= 0 ? 1 : 0)
        @constraint(model, UP_TIME[i in 1:size.gen, t in 1:size.stages], sum(on[i, j] for j in max(t-data.up_time[i]+1,1):t) + past(i,t) <= c[i, t])
        past(i, t) = (-data.IST[i] > 0 && -data.IST[i] + t - data.down_time[i] <= 0 ? 1 : 0)
        @constraint(model, DOWN_TIME[i in 1:size.gen, t in 1:size.stages], sum(off[i, j] for j in max(t-data.down_time[i]+1,1):t) + past(i,t) <= 1 - c[i, t])
    end
end

function add_KCL_pos!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_contingency
        g_pos = model[:g_pos]
        f_pos = model[:f_pos]
        def_pos = model[:def_pos]
        g_cut = model[:g_cut]
        fake_demand = model[:fake_demand]
        @constraint(model, KCL_pos[i in 1:size.bus, t in 1:size.stages, k=1:size.K], sum(g_pos[j, t, k] for j in 1:size.gen if data.gen2bus[j] == i) + sum(f_pos[j, t, k] * data.A[i, j] for j in 1:size.circ) + def_pos[i, t, k] - g_cut[i, t, k] == fake_demand[i, t])
    end
end

function add_KVL_pos!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_contingency && options.use_kirchhoff
        f_pos = model[:f_pos]
        theta_pos = model[:theta_pos]
        @constraint(model, KVL_pos[i in 1:size.circ, t in 1:size.stages, k=1:size.K], f_pos[i, t, k] == data.contingency_lin[i, k] * sum(theta_pos[j, t, k] * data.A[j, i] for j in 1:size.bus) / data.x[i])
    end
end

function add_RAMP_pos!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_ramp && options.use_commit && options.use_contingency
        g_pos = model[:g_pos]
        c = model[:c]
        on = model[:on]
        off = model[:off]
        @constraint(model, RAMP_UP_pos_0[i in 1:size.gen, k=1:size.K] , data.contingency_gen[i,k]*(on[i,1]*data.startup[i] + data.ramp_up[i]*data.ISC[i]) >= data.contingency_gen[i,k]*(g_pos[i,1,k] - data.ISP[i]))
        @constraint(model, RAMP_UP_pos[t in 1:size.stages-1, i in 1:size.gen, k=1:size.K], data.contingency_gen[i,k]*(on[i,t+1]*data.startup[i] + data.ramp_up[i]*c[i,t]) >= data.contingency_gen[i,k]*(g_pos[i,t+1,k] - g_pos[i,t,k]))
        @constraint(model, RAMP_DOWN_pos_0[i in 1:size.gen, k=1:size.K], data.contingency_gen[i,k]*(-data.ramp_down[i]*data.ISC[i] -off[i,1]*data.shutdown[i]) <= data.contingency_gen[i,k]*(g_pos[i,1,k] - data.ISP[i]))
        @constraint(model, RAMP_DOWN_pos[t in 1:size.stages-1, i in 1:size.gen, k=1:size.K], data.contingency_gen[i,k]*(-data.ramp_down[i]*c[i,t+1] -off[i,t+1]*data.shutdown[i]) <= data.contingency_gen[i,k]*(g_pos[i,t+1,k] - g_pos[i,t,k]))
    elseif options.use_ramp && options.use_contingency
        g_pos = model[:g_pos]
        @constraint(model, RAMP_UP_pos_0[i in 1:size.gen, k=1:size.K], data.ramp_up[i] >= g_pos[i, 1, k] - data.ISP[i])
        @constraint(model, RAMP_DOWN_pos_0[i in 1:size.gen, k=1:size.K], -data.ramp_down[i] <= g_pos[i, 1, k] - data.ISP[i])
        @constraint(model, RAMP_UP_pos[t in 1:size.stages-1, i in 1:size.gen, k=1:size.K], data.ramp_up[i] >= g_pos[i, t+1, k] - g_pos[i, t, k])
        @constraint(model, RAMP_DOWN_pos[t in 1:size.stages-1, i in 1:size.gen, k=1:size.K], -data.ramp_down[i] <= g_pos[i, t+1, k] - g_pos[i, t, k])
    end
end

function add_DEF_CUT_MAX!(prb::Problem)
    model = prb.model
    size = prb.size
    options = prb.options

    if options.use_contingency
        def_pos = model[:def_pos]
        def_pos_max = model[:def_pos_max]
        g_cut = model[:g_cut]
        g_cut_max = model[:g_cut_max]
        @constraint(model, DEF_MAX[i in 1:size.bus, t in 1:size.stages, k=1:size.K], def_pos_max[i, t] >= def_pos[i, t, k])
        @constraint(model, GEN_MAX[i in 1:size.bus, t in 1:size.stages, k=1:size.K], g_cut_max[i, t] >= g_cut[i, t, k])
    end
end

function add_GEN_DEV!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size
    options = prb.options

    if options.use_contingency
        g = model[:g]
        g_pos = model[:g_pos]
        reserve_up = model[:reserve_up]
        reserve_down = model[:reserve_down]
        @constraint(model, GEN_DEV_MIN[i in 1:size.gen, t in 1:size.stages, k=1:size.K], (g[i, t] - reserve_down[i, t]) * data.contingency_gen[i, k] <= g_pos[i, t, k])
        @constraint(model, GEN_DEV_MAX[i in 1:size.gen, t in 1:size.stages, k=1:size.K], (g[i, t] + reserve_up[i, t]) * data.contingency_gen[i, k] >= g_pos[i, t, k])
    end
end

function add_DUAL_FISHER!(prb::Problem)
    model = prb.model
    data = prb.data
    size = prb.size

    fake_demand = model[:fake_demand]

    @constraint(model, DUAL_FISHER[i=1:size.bus, t=1:size.stages], fake_demand[i,t] == data.demand[i,t])
end
