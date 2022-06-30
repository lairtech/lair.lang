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
    println(expr)
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
            println("Unkown expression: $input")
            continue
        end
        result  = evalExpr(expr)
        printExpr(result)
    end
end