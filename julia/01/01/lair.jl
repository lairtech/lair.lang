module Lair

function parse(input::String)
    input
end

function eval(expr)
    expr
end

function print(expr)
    println(expr)
end

function repl()
    while true
        Base.print("lair>")
        input = readline()
        if input == "exit"
            return
        end
        expr = parse(input)
        result  = eval(expr)
        print(result)
    end
end

end