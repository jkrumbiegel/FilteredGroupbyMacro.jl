macro dt(exp)
    # dump(exp)

    exp.head != :ref && error("You have to use [] syntax.")
    df = exp.args[1]
    nargs = length(exp.args) - 1
    args = exp.args[2:end]

    filterexp = args[1]
    byexp = args[2]
    actionexps = args[3:end]

    conv_actionexps = convert_kwexp.(actionexps)

    # dump(actionexp)

    quote
        by($df[$filterexp, :], $byexp, $(conv_actionexps...))
    end
end


function convert_kwexp(kwexp)
    @assert kwexp.head == :kw
    kw = kwexp.args[1]
    exp = kwexp.args[2]

    replace_quotenodes!(exp)
    quotenodes = all_quotenodes(exp)

    :($(esc(kw)) = ($(quotenodes...),) => $(esc(:subdf)) -> $exp)
end

function all_quotenodes(exp)
    quotenodes = QuoteNode[]
    for a in exp.args
        if a isa QuoteNode
            push!(quotenodes, a)
        elseif a isa Expr
            append!(quotenodes, all_quotenodes(a))
        end
    end
    quotenodes
end

function replace_quotenodes!(exp)
    for (i, a) in enumerate(exp.args)
        if a isa QuoteNode
            sym = a.value
            exp.args[i] = :($(esc(:subdf)).$sym)
        elseif a isa Expr
            replace_quotenodes!(a)
        end
    end
    exp
end


@macroexpand @dt df[!, :b, y = :a .^ 2]

@dt df[!, :b, hello = :a .^ 2, y = log.(:a)]

function test(df)
    by(df, :b, x = (:a,) => x -> x.:a .^ 2)
end

function test2(df)
    @dt df[!, :b, hello = :a .^ 2, y = log.(:a)]
end

test(df)
test2(df)


function replace_filterexp(fexp)
    if fexp == Symbol(:)
        return :()
    else
    end
end

@dt df[:, (x = sum(:a), y = exp(:c + :d)), :b]

by(df[!, :], :b, :a => sum)

@dt hello(3)

dump(quote df[:, a, a = b, c = x + y] end)


by()


using RDatasets

data = RDatasets.dataset("datasets", "iris")

by(data, :Species, newval = (:SepalLength, :SepalWidth) => a -> a[2])

@dt data[!, :Species, square = sum(:SepalLength .* :SepalWidth)]

by(data, :Species)