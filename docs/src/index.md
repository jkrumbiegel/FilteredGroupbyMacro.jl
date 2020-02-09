# FilteredGroupbyMacro.jl

## Filtered split-apply-combine as in R's data.table

FilteredGroupbyMacro.jl offers a macro `@by` with which
split-apply-combine operations on filtered data frames can be expressed concisely. It is very similar in nature
to the `[i,j,by]` indexing that the well-known package data.table in the R ecosystem uses.

The order of arguments is slightly different. Here, you have to specify:

`[filter, grouping_keys, new_column_keyword_args...]`

An example with the well-known *diamonds* dataset:

```@example
using RDatasets
using FilteredGroupbyMacro
using StatsBase

diamonds = dataset("ggplot2", "diamonds")

# filter by Price and Carat
# then group by Cut
# finally compute new columns with keyword names
@by diamonds[(:Price .> 3000) .& (:Carat .> 0.3), :Cut,
    MeanPricePerCarat = mean(:Price) / mean(:Carat),
    MostFreqColor = sort(collect(countmap(:Color)), by = last)[end][1]]
```

Internally, the macro transforms the indexing syntax to the functional equivalent of
the following standard DataFrames function calls:

```@example
using RDatasets # hide
using FilteredGroupbyMacro # hide
using StatsBase # hide

diamonds = dataset("ggplot2", "diamonds") # hide

by(diamonds[(diamonds.Price .> 3000) .& (diamonds.Carat .> 0.3), :], :Cut,
    MeanPricePerCarat = (:Price, :Carat) => x -> mean(x.Price) / mean(x.Carat),
    MostFreqColor = :Color => x -> sort(collect(countmap(x)), by = last)[end][1])
```

As you can see there are a couple of redundancies in the default syntax. Especially for computations using multiple columns, the standard `new_column = columns => function` syntax is much more verbose and less readable.

## Assignment syntax

You can also use assignment syntax with the `:=` operator. This is not a mutating
operation as in R's data.table but returns a new `DataFrame`, in which the result of the
split-apply-combine operation is joined with the original data. This is handy if you
want to keep working with a full dataset after calculating group-wise summary statistics
which are then repeated for each group row.

```@example
using FilteredGroupbyMacro # hide
using DataFrames # hide
df = DataFrame(a = repeat(1:3, 3), b = repeat('a':'c', 3))
@by df[!, :b, sum_a := sum(:a)]
```

Compare this to the non-assignment syntax:

```@example
using FilteredGroupbyMacro # hide
using DataFrames # hide
df = DataFrame(a = repeat(1:3, 3), b = repeat('a':'c', 3)) # hide
@by df[!, :b, sum_a = sum(:a)]
```
