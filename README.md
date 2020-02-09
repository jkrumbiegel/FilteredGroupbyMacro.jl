# GroupbyIndexingMacro

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jkrumbiegel.github.io/GroupbyIndexingMacro.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jkrumbiegel.github.io/GroupbyIndexingMacro.jl/dev)
[![Build Status](https://travis-ci.com/jkrumbiegel/GroupbyIndexingMacro.jl.svg?branch=master)](https://travis-ci.com/jkrumbiegel/GroupbyIndexingMacro.jl)
[![Codecov](https://codecov.io/gh/jkrumbiegel/GroupbyIndexingMacro.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jkrumbiegel/GroupbyIndexingMacro.jl)


## Filtered split-apply-combine as in R's data.table

GroupbyIndexingMacro.jl offers a macro `@by` with which a concise syntax for filtered
split-apply-combine operations can be expressed concisely. It is very similar in nature
to the `[i,j,by]` indexing that the well-known package data.table in the R ecosystem uses.

The order is slightly different. Here, you have to specify:

`[filter, grouping_keys, new_column_keyword_args...]`

An example with the well-known *diamonds* dataset:

```julia
using RDatasets
using GroupbyIndexingMacro
using StatsBase

diamonds = dataset("ggplot2", "diamonds")

# filter by Price and Carat
# then group by Cut
# finally compute new columns with keyword names
@by diamonds[(:Price .> 3000) .& (:Carat .> 0.3), :Cut,
    MeanPricePerCarat = mean(:Price) / mean(:Carat),
    MostFreqColor = sort(collect(countmap(:Color)), by = last)[end][1]]
```

Compare this to the default DataFrames syntax:

```julia
by(diamonds[(diamonds.Price .> 3000) .& (diamonds.Carat .> 0.3), :], :Cut,
    MeanPricePerCarat = (:Price, :Carat) => x -> mean(x.Price) / mean(x.Carat),
    MostFreqColor = :Color => x -> sort(collect(countmap(x)), by = last)[end][1])
```

You can also use assignment syntax to join the groupby result with the filtered table:

```julia
using GroupbyIndexingMacro # hide
using DataFrames # hide
df = DataFrame(a = repeat(1:3, 3), b = repeat('a':'c', 3))
# the result of this will be df with a new column sum_a
# that contains the same sum_a for every row in each group based on :b
@by df[!, :b, sum_a := sum(:a)]
```