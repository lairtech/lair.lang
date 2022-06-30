function parseExp(input::String)
    input
end

function evalExp(expr)
    expr
end

function printExp(expr)
    println(expr)
end

function lairRepl()
    while true
        print("lair>")
        input = readline()
        if input == "exit"
            return
        end
        expr = parseExp(input)
        result  = evalExp(expr)
        printExp(result)
    end
end