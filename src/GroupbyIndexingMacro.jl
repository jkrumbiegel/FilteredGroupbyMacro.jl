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


    # additional keyword parameters after the ;
    kwparams = if args[1] isa Expr && args[1].head == :parameters
        params = args[1].args
        deleteat!(args, 1)
        esc(params...)
    else
        # empty splatted keyword params
        esc(:(NamedTuple()...))
    end

    filterexp = args[1]
    byexp = args[2]

    action_exps = args[3:end]

    validate_byexp(byexp)

    conv_filterexp = replace_quotenodes_filterexp!(filterexp, df)

    assign_mode = is_assign_kwarg(action_exps[1])

    # for x := sum(:y) style
    if assign_mode

        conv_assign_exps = convert_assignexp.(action_exps)

        quote

            tempdf = $(esc(DataFrames.by))(
                # filter
                $(esc(df))[$(esc(conv_filterexp)), $(esc(:))],
                # groupby
                $byexp;
                # new columns from computations
                $(conv_assign_exps...),
                $kwparams
            )

            $(esc(DataFrames.join))($(esc(df)), tempdf, on = $byexp)

        end


    # for x = sum(:y) style
    else

        conv_kwexps = convert_kwexp.(action_exps)

        quote
            $(esc(DataFrames.by))(
                # filter
                $(esc(df))[$(esc(conv_filterexp)), $(esc(:))],
                # groupby
                $byexp;
                # new columns from computations
                $(conv_kwexps...),
                $kwparams
            )
        end

    end
end

is_assign_kwarg(x) = false
is_assign_kwarg(exp::Expr) = exp.head == Symbol(":=")

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

function convert_assignexp(assignexp)
    !is_assign_kwarg(assignexp) && error("Expected an assignment keyword argument but received $assignexp")

    kw = assignexp.args[1]
    exp = assignexp.args[2]

    replace_quotenodes!(exp)
    quotenodes = all_quotenodes(exp)

    :($(esc(kw)) = ($(quotenodes...),) => $(esc(:subdf)) -> $(esc(exp)))
end

all_quotenodes(any) = QuoteNode[]
all_quotenodes(qn::QuoteNode) = [qn]

function all_quotenodes(exp::Expr)
    quotenodes = QuoteNode[]
    for a in exp.args
        append!(quotenodes, all_quotenodes(a))
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
