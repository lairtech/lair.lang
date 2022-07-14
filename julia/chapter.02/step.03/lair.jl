module Lair

include("peg.jl")

booleanPattern = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false

function parse(input::String)
    matchedExpr = match(booleanPattern, input)
    if matchedExpr === nothing
        return nothing
    end
    index, capture = matchedExpr
    capture
end

function eval(expr)
    expr
end

function print(expr)
    if expr == true
        println("true")
    elseif expr == false
        println("false")
    else
        println("Unkown expression: $expr")
    end
end

function repl()
    while true
        Base.print("lair>")
        input = readline()
        if input == "exit"
            return
        end
        expr = parse(input)
        if expr === nothing
            println("Unable to parse expression: \"$input\"")
            continue
        end
        result  = eval(expr)
        print(result)
    end
end

end