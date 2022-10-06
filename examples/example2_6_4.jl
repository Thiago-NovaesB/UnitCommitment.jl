using UnitCommitment
using HiGHS
using JuMP

prb = UnitCommitment.Problem()
data = prb.data
options = prb.options
size = prb.size
options.solver = HiGHS.Optimizer


data.f_max = zeros(8).+100
data.x = zeros(8).+1.25
data.gen2bus = [1, 2, 3]
data.A = [1 1 1 0 0 0 0 0;
          0 0 0 1 1 1 0 0;
          0 0 0 0 0 0 1 1;
          -1 0 0 -1 0 0 0 0;
          0 -1 0 0 -1 0 -1 0;
          0 0 -1 0 0 -1 0 -1]

size.bus = 6
size.circ = 8
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
data.demand = [0 0 0 0 0 0;
               0 0 0 0 0 0;
               0 0 0 0 0 0;
               100 100 80 140 100 80;
               90 100 80 30 90 60;
               50 50 40 0 40 50]
options.use_kirchhoff = true
options.use_ramp = true
options.use_commit = true
options.use_up_down_time = true
options.use_contingency = false

data.def_cost = zeros(size.bus) .+ 1000


UnitCommitment.build_model(prb)
UnitCommitment.solve_model(prb)
UnitCommitment.rerun_model(prb)


dual.(prb.model[:DUAL_FISHER])
