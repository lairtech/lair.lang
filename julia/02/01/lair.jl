module Lair

function parse(input::String)
    if input == "true"
        return true
    elseif input == "false"
        return false
    end
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