using GroupbyIndexingMacro
using DataFrames
using Test

df = DataFrame(
    a = repeat(1:10, inner = 10),
    b = repeat('a':'e', inner = 20),
    c = 1:100,
)

@testset "GroupbyIndexingMacro.jl" begin
    dt_1 = @dt df[!, :b, d = :a .* :c]
    by_1 = by(df, :b, d = (:a, :c) => x -> x.a .* x.c)

    # do both versions do the same thing?
    @test dt_1 == by_1

    # test chaining of multiple groupings
    dt_2 = @dt dt_1[!, :b, e = sum(:d .^ 2)]
    @test dt_2 == @dt df[!, :b, d = :a .* :c][
        !, :b, e = sum(:d .^ 2)]


    # test filtering
    dt_3 = @dt df[:a .< 8, :b, d = sum(:c)]
    by_3 = by(df[df.a .< 8, :], :b, d = (:c,) => x -> sum(x.c))
    @test dt_3 == by_3
end

@testset "In Function" begin
    function test(df)
        @dt df[!, :a, csum = sum(:c)]
    end

    dt = test(df)

    function test2(df)
        localsumfunc = x -> sum(x)
        @dt df[!, :a, csum = localsumfunc(:c)]
    end

    dt2 = test2(df)
end