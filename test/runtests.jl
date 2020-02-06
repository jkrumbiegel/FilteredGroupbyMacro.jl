using GroupbyIndexingMacro
using DataFrames
using Test

df = DataFrame(
    a = repeat(1:10, inner = 10),
    b = repeat('a':'e', inner = 20),
    c = 1:100,
)

@testset "Base functionality" begin
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

@testset "Sorted keyword" begin
    df2 = DataFrame(a = 2:-1:1, b = 1:2)
    dt = @dt df2[!, :a, c = 1 * :b]
    @test dt.a == [2, 1]
    @test dt.c == [1, 2]

    dt2 = @dt df2[!, :a, c = 1 * :b; sort = true]
    @test dt2.a == [1, 2]
    @test dt2.c == [2, 1]
end

@testset "Assign syntax" begin
    df2 = DataFrame(a = [1, 1, 2, 2], b = 1:4)
    dt = @dt df2[!, :a, c := sum(:b)]
    @test dt == DataFrame(a = [1, 1, 2, 2], b = 1:4, c = [3, 3, 7, 7])
end

# @testset "Single symbol" begin
#     df2 = DataFrame(a = 2:-1:1, b = 1:2)
#     dt = @dt df2[!, :a, c = :b] # just :b
#     @test dt.a == [2, 1]
#     @test dt.c == [1, 2]
# end
