function parseExpr(input::String)
    if input == "true"
        return true
    elseif input == "false"
        return false
    end
end

function evalExpr(expr)
    expr
end

function printExpr(expr)
    if expr == true
        println("true")
    elseif expr == false
        println("false")
    else
        println("Unkown expression: $expr")
    end
end

function lairRepl()
    while true
        print("lair>")
        input = readline()
        if input == "exit"
            return
        end
        expr = parseExpr(input)
        if expr === nothing
            println("Unable to parse expression: \"$input\"")
            continue
        end
        result  = evalExpr(expr)
        printExpr(result)
    end
end