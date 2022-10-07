using Test
using UnitCommitment
using HiGHS
using JuMP

include("test_def.jl")

@testset "All Cases" begin
    @testset "Case01" begin
        prb = teste_1()
        @test objective_value(prb.model) ≈ 9475
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case02" begin
        prb = teste_2()
        @test objective_value(prb.model) ≈ 11800
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case03" begin
        prb = teste_3()
        @test objective_value(prb.model) ≈ 12500
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case04" begin
        prb = teste_4()
        @test objective_value(prb.model) ≈ 9475
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case05" begin
        prb = teste_5()
        @test objective_value(prb.model) ≈ 11675
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case06" begin
        prb = teste_6()
        @test objective_value(prb.model) ≈ 13325
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
    @testset "Case07" begin
        prb = teste_7()
        @test termination_status(prb.model) == MOI.OPTIMAL
    end
end