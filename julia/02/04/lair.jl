module Lair

include("peg.jl")

booleanPattern = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false
integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i) # matches an chars in between 0-9 with one leading '-' or '+' and convert that to an Integer
primitivePattern = booleanPattern + integerPattern

function parse(input::String)
    matchedExpr = match(primitivePattern, input)
    if matchedExpr === nothing
        return nothing
    end
    index, capture = matchedExpr
    capture
end

function eval(expr)
    expr
end

function print(expr::Bool)
    if expr == true
        println("true")
    else expr == false
        println("false")
    end
end

function print(expr::Integer)
    println(expr)
end

function print(expr::Any)
    println("Unkown expression: $expr")
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