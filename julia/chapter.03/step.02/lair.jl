module Lair

include("peg.jl")

function parse(input::String)
    matchedExpr = match(grammar, input)
    if matchedExpr === nothing
        return nothing
    end
    index, capture = matchedExpr
    capture
end

nativeTypes = Dict()

function typeOf(expr::Function)
    :PrimitiveFunction
end

function typeOf(expr)
    nativeTypes[typeof(expr)]
end

evaluators = Dict()
applicators = Dict()

function eval(expr, env)
    apply(evaluators[typeOf(expr)], expr, env)
end

function apply(applicator, args, env)
    if typeOf(applicator) == :PrimitiveFunction
        applicator(args, env)
    else
        apply(applicators[typeOf(applicator)], append!([applicator], args), env)
    end
end

serializers = Dict()

function print(expr)
    serializer = serializers[typeOf(expr)]
    if serializer !== nothing
        println(serializer(expr))
    else
        println("No serializer set for type: $(typeOf(expr))")
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
        result  = eval(expr, nothing)
        print(result)
    end
end

grammar = Dict()
grammar[1] = :Primitives
grammar[:Primitives] = :Boolean + :Integer + :String

# Booleans
grammar[:Boolean] = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false
nativeTypes[Bool] = :Boolean
evaluators[:Boolean] = (expr, env) -> expr
serializers[:Boolean] = expr -> expr ? "true" : "false"
# Integers
grammar[:Integer] = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i) # matches an chars in between 0-9 with one leading '-' or '+' and convert that to an Integer
nativeTypes[Int64] = :Integer
evaluators[:Integer] = (expr, env) -> expr
serializers[:Integer] = expr -> expr
# Strings
grammar[:StringEscapes] = "\\\"" + "\\\\" + "\\n" + "\\r" + "\\t" # all the escape pattern we support
grammar[:String] = "\"" * c((:StringEscapes + (1 - ("\"" + "\\"))) ^ 0) * "\"" # match the escape pattern or any char except " or \ (so we only support the listed escape sequences)
nativeTypes[String] = :String
evaluators[:String] = (expr, env) -> expr
serializers[:String] = expr -> "\"$expr\""

end
