using Test
using UnitCommitment
using HiGHS
using JuMP

include("test_def.jl")

@testset "All Cases" begin
    @testset "Case01" begin
        prb = teste_1()
        g = value.(prb.model[:g])
        @test g[1,1] ≈ 100.0
        @test g[2,1] ≈ 0.0
        @test objective_value(prb.model) ≈ 10000.0
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case02" begin
        prb = teste_2()
        g = value.(prb.model[:g])
        @test g[1,1] ≈ 80.0
        @test g[2,1] ≈ 20.0
        @test objective_value(prb.model) ≈ 11000.0
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case03" begin
        prb = teste_3()
        g = value.(prb.model[:g])
        @test g[1,1] ≈ 50.0
        @test g[2,1] ≈ 50.0
        @test objective_value(prb.model) ≈ 13750.0
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
end