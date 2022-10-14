using UnitCommitment
using HiGHS
using JuMP
using DelimitedFiles

prb = UnitCommitment.Problem()
data = prb.data
options = prb.options
size = prb.size
options.solver = HiGHS.Optimizer


data.f_max = zeros(8).+100
data.f_max[3] = 40
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
size.K = 11
# data.contingency_gen = reshape([false true true], 3, 1)
# data.contingency_lin = reshape([true true true true true true true true], 8, 1)

data.contingency_gen = [false true true true true true true true true true true;
                        true false true true true true true true true true true;
                        true true false true true true true true true true true]
data.contingency_lin = [true true true false true true true true true true true;
                        true true true true false true true true true true true;
                        true true true true true false true true true true true;
                        true true true true true true false true true true true;
                        true true true true true true true false true true true;
                        true true true true true true true true false true true;
                        true true true true true true true true true false true;
                        true true true true true true true true true true false]

data.gen_cut_cost = [10000000, 10000000, 10000000, 10000000, 10000000, 10000000]
data.def_cost_rev = [10000000, 10000000, 10000000, 10000000, 10000000, 10000000]
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
data.exo_up = [0, 0, 0, 0, 0, 0]
data.exo_down = [0, 0, 0, 0, 0, 0]
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
options.use_contingency = true

data.def_cost = zeros(size.bus) .+ 5000


UnitCommitment.build_model(prb)
UnitCommitment.solve_model(prb)
termination_status(prb.model)
UnitCommitment.rerun_model(prb)

objective_value(prb.model)

dual.(prb.model[:DUAL_FISHER])

print("Custo total do sistema, considerando contingências:  ")
println(round(objective_value(prb.model)))

print("\n")
println("Geração:")
writedlm(stdout,round.(value.(prb.model[:g]), digits = 1))
println("*colunas: horas (de 1 a 6); linhas: geradores (do 1 ao 3)")

print("\n")
println("Dual:")
writedlm(stdout,round.(dual.(prb.model[:DUAL_FISHER])))
println("*colunas: horas (de 1 a 6); linhas: barras (1 a 6)")

print("\n")
println("Deficit:")
writedlm(stdout,value.(prb.model[:def]))
println("*colunas: horas (de 1 a 6); linhas: barras (1 a 6)")

print("\n")
println("Status dos geradores:")
writedlm(stdout,round.(value.(prb.model[:c])))
println("*colunas: horas (de 1 a 6); linhas: geradores (do 1 ao 3)")

print("\n")
println("Reserva de subida:")
writedlm(stdout,round.(value.(prb.model[:reserve_up]),digits=1))
println("*colunas: horas (de 1 a 6); linhas: geradores (do 1 ao 3)")

print("\n")
println("Reserva de descida:")
writedlm(stdout,round.(value.(prb.model[:reserve_down]),digits=1))
println("*colunas: horas (de 1 a 6); linhas: geradores (do 1 ao 3)")

print("\n")
println("Fluxos:")
writedlm(stdout,round.(value.(prb.model[:f]),digits=2))
println("*colunas: horas (de 1 a 6); linhas: linhas de transmissão (do 1 ao 8)")

print("\n")
println("Geração pós contingência (quando o gerador 1 falha):")
writedlm(stdout,round.(value.(prb.model[:g_pos])[:,:,1],digits=1))
println("*colunas: horas (de 1 a 6); linhas: linhas de transmissão (do 1 ao 8)")

print("\n")
println("Deficit pós contingência (quando o gerador 1 falha):")
writedlm(stdout,round.(value.(prb.model[:def_pos])[:,:,1],digits=1))
println("*colunas: horas (de 1 a 6); linhas: barras (1 a 6)")