
using IntervalConstraintProgramming
using ValidatedNumerics

using Base.Test


@testset "Utilities" begin
    @test IntervalConstraintProgramming.unify_variables([:a, :c], [:c, :b]) == ([:a,:b,:c], [1,3], [3,2], [1,0,2], [0,2,1])
end

@testset "Contractor" begin
    x = y = -∞..∞
    X = IntervalBox(x, y)

    C = @contractor x^2 + y^2

    @test C(-∞..1, x, y) == (-1..1, -1..1)
end

@testset "Separators" begin
    II = -100..100
    X = IntervalBox(II, II)
    S = @constraint x^2 + y^2 <= 1

    @test typeof(S) == IntervalConstraintProgramming.ConstraintSeparator

    inner, outer = S(X)
    @test inner == (-1..1, -1..1)
    @test outer == (II, II)

    X = IntervalBox(-∞..∞, -∞..∞)
    inner, outer = S(X)
    @test inner == (-1..1, -1..1)
    @test outer == (-∞..∞, -∞..∞)
end

@testset "pave" begin
    S1a = @constraint x > 0
    S1b = @constraint y > 0

    S1 = S1a ∩ S1b
    paving = pave(S1, IntervalBox(-3..3, -3..3), 0.1)

    @test paving.inner == [IntervalBox(1.5..3, 0..3), IntervalBox(0..1.5, 0..3)]
    @test isempty(paving.boundary) == true

    S2 = S1a ∪ S1b
    paving = pave(S2, IntervalBox(-3..3, -3..3), 0.1)
    @test paving.inner == [IntervalBox(-3..0, 0..3), IntervalBox(0..3, -3..3)]
    @test isempty(paving.boundary) == true


    S3 = @constraint x^2 + y^2 <= 1
    X = IntervalBox(-∞..∞, -∞..∞)
    paving = pave(S3, X, 1)

    @test paving.inner == [IntervalBox(Interval(0.0, 0.5), Interval(0.0, 0.8660254037844386)),
                    IntervalBox(Interval(0.0, 0.5), Interval(-0.8660254037844386, 0.0)),
                    IntervalBox(Interval(-0.5, 0.0), Interval(0.0, 0.8660254037844386)),
                    IntervalBox(Interval(-0.5, 0.0), Interval(-0.8660254037844386, 0.0))]

    @test paving.boundary == [ IntervalBox(Interval(0.5, 1.0), Interval(0.0, 0.8660254037844387)),
                        IntervalBox(Interval(0.0, 0.5), Interval(0.8660254037844386, 1.0)),
                        IntervalBox(Interval(0.5, 1.0), Interval(-0.8660254037844387, 0.0)),
                        IntervalBox(Interval(0.0, 0.5), Interval(-1.0, -0.8660254037844386)),
                        IntervalBox(Interval(-0.5, 0.0), Interval(0.8660254037844386, 1.0)),
                        IntervalBox(Interval(-1.0, -0.5), Interval(0.0, 0.8660254037844387)),
                        IntervalBox(Interval(-0.5, 0.0), Interval(-1.0, -0.8660254037844386)),
                        IntervalBox(Interval(-1.0, -0.5), Interval(-0.8660254037844387, 0.0))]
end

# @testset "Constants" begin
#     let a = 3
#         x = y = -∞..∞
#         X = IntervalBox(x, y)
#         S4 = @constraint x^2 + y^2 - $a <= 0
#         paving = pave(S4, X)
#
#         @test paving.ϵ == 0.01
#         @test length(paving.inner) == 1532
#         @test length(paving.boundary) == 1536
#     end
# end


@testset "Volume" begin
    x = 3..5
    @test Vol(x).bounds == 2

    V = Vol(IntervalBox(-1..1.5, 2..3.5))
    @test typeof(V) == IntervalConstraintProgramming.Vol{2, Float64}
    @test V.bounds == 3.75

end

@testset "Functions" begin
    @function f(x) = 4x
    C1 = @contractor f(x)
    A = 0.5..1
    x = 0..1

    @test C1(A, x) == 0.125..0.25   # x such that 4x ∈ A=[0.5, 1]


    C2 = @constraint f(x) ∈ [0.5, 0.6]
    X = IntervalBox(0..1)

    paving = pave(C2, X)
    @test length(paving.inner) == 2
    @test length(paving.boundary) == 2


    C3 = @constraint f(f(x)) ∈ [0.4, 0.8]
    @test length(paving.inner) == 2
    @test length(paving.boundary) == 2

end
