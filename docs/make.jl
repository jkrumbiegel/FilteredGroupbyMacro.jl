using Documenter, GroupbyIndexingMacro

makedocs(;
    modules=[GroupbyIndexingMacro],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jkrumbiegel/GroupbyIndexingMacro.jl/blob/{commit}{path}#L{line}",
    sitename="GroupbyIndexingMacro.jl",
    authors="Julius Krumbiegel",
    assets=String[],
)

deploydocs(;
    repo="github.com/jkrumbiegel/GroupbyIndexingMacro.jl",
)
