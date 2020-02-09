using Documenter, FilteredGroupbyMacro

makedocs(;
    modules=[FilteredGroupbyMacro],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jkrumbiegel/FilteredGroupbyMacro.jl/blob/{commit}{path}#L{line}",
    sitename="FilteredGroupbyMacro.jl",
    authors="Julius Krumbiegel",
    assets=String[],
)

deploydocs(;
    repo="github.com/jkrumbiegel/FilteredGroupbyMacro.jl",
)
