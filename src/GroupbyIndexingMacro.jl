module GroupbyIndexingMacro

import DataFrames

export @dt

macro dt(exp)
    # dump(exp)

    exp.head != :ref && error("You have to use [] syntax.")

    df = exp.args[1]

    # enable chained calls by applying the macro again if df is actually another nested
    # ref expression
    if df isa Expr
        df = :(@dt($df))
    end


    # nargs = length(exp.args) - 1
    args = exp.args[2:end]

    filterexp = args[1]
    byexp = args[2]
    kwexps = args[3:end]

    validate_byexp(byexp)

    conv_filterexp = replace_quotenodes_filterexp!(filterexp, df)
    conv_kwexps = convert_kwexp.(kwexps)

    quote
        $(esc(DataFrames.by))(
            # filter
            $(esc(df))[$(esc(conv_filterexp)), $(esc(:))],
            # groupby
            $byexp;
            # new columns from computations
            $(conv_kwexps...),
        )
    end
end

is_kwarg(x) = false
is_kwarg(exp::Expr) = exp.head == :kw

function validate_byexp(exp)
    is_kwarg(exp) && error("Groupby expression missing, found keyword argument $exp instead.")
end

function convert_kwexp(kwexp)
    !is_kwarg(kwexp) && error("Expected a keyword argument but received $kwexp")
    kw = kwexp.args[1]
    exp = kwexp.args[2]

    replace_quotenodes!(exp)
    quotenodes = all_quotenodes(exp)

    :($(esc(kw)) = ($(quotenodes...),) => $(esc(:subdf)) -> $(esc(exp)))
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

replace_quotenodes!(any) = any

function replace_quotenodes!(exp::Expr)
    for (i, a) in enumerate(exp.args)
        if a isa QuoteNode
            sym = a.value
            exp.args[i] = :(subdf.$sym)
        elseif a isa Expr
            replace_quotenodes!(a)
        end
    end
    exp
end

replace_quotenodes_filterexp!(any, dfexp) = any

function replace_quotenodes_filterexp!(exp::Expr, dfexp)
    for (i, a) in enumerate(exp.args)
        if a isa QuoteNode
            sym = a.value
            exp.args[i] = :($dfexp.$sym)
        elseif a isa Expr
            replace_quotenodes_filterexp!(a, dfexp)
        end
    end
    exp
end

end # module
