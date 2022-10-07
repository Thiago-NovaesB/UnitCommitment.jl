using UnitCommitment
using HiGHS
using JuMP

prb = UnitCommitment.Problem()
data = prb.data
options = prb.options
size = prb.size
options.solver = HiGHS.Optimizer


data.f_max = [0]
data.x = [1]
data.gen2bus = [1, 1, 1]
data.A = zeros(1,1)

size.bus = 1
size.circ = 1
size.stages = 6
size.gen = 3
data.g_max = [300, 200, 100]
data.g_min = [80, 50, 30]
data.ramp_up = [50, 60, 70]
data.ramp_down = [30, 40, 50]
data.startup = [100, 70, 40]
data.shutdown = [80, 50, 30]
data.up_time = [3, 2, 1]
data.down_time = [2, 2, 2]
data.reserve_up_max = [40, 50, 60]
data.reserve_down_max = [20, 30, 40]
data.gen_cost = [5, 15, 30]
data.reserve_up_cost = [10, 25, 45]
data.reserve_down_cost = [10, 25, 45]
data.on_cost = [800, 500, 250]
data.off_cost = [400, 250, 125]
data.ISC = [1, 0, 0]
data.ISP = [120, 0, 0]
data.IST = [2, -99, -99]
data.exo_up = [10, 10, 10, 10, 10, 10]
data.exo_down = [0, 0, 0, 0, 0, 0]
data.demand = reshape([240, 250, 200, 170, 230, 190], 1,6)
options.use_kirchhoff = false
options.use_ramp = true
options.use_commit = true
options.use_up_down_time = true
options.use_contingency = false

data.def_cost = zeros(size.bus) .+ 1000


UnitCommitment.build_model(prb)
UnitCommitment.solve_model(prb)
UnitCommitment.rerun_model(prb)


dual.(prb.model[:DUAL_FISHER])

objective_value(prb.model)

value.(prb.model[:g])