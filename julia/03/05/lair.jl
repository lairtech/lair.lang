module Lair

using Pkg
Pkg.add("FunctionalCollections")
using FunctionalCollections

include("peg.jl")
include("environment.jl")

import Base.typename # needed to only get the type name and not also it's parameters that we don't care for now

function parse(input::String)
    matchedExpr = match(grammar, input)
    if matchedExpr === nothing
        return nothing
    end
    index, capture = matchedExpr
    if length(input) != index -1
        return nothing
    end
    capture
end

nativeTypes = Dict()

function typeOf(expr::Function)
    :PrimitiveFunction
end

function typeOf(expr)
    nativeTypes[typename(typeof(expr))]
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
        apply(applicators[typeOf(applicator)], append(PersistentVector{Any}([applicator]), args), env)
    end
end

serializers = Dict()

function serialize(expr)
    serializer = serializers[typeOf(expr)]
    if serializer !== nothing
        return serializer(expr)
    end
end

function print(expr)
    println(serialize(expr))
end

function repl(env::Environment = globalEnviroment)
    while true
        try
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
            result  = eval(expr, env)
            print(result)
        catch e
            println("Error: "  * sprint(showerror, e))
        end
    end
end

grammar = Dict()
grammar[1] = :Expression
grammar[:Expression] = :WhiteSpaces * (:Code + :Collection + :Atom) * :WhiteSpaces
grammar[:Atom] = :Boolean + :Integer + :String + :Symbol
grammar[:Collection] = :Array
grammar[:Code] = :Application

grammar[:WhiteSpace] = " " + "\t" + "\r" + "\n"
grammar[:WhiteSpaces] = p(:WhiteSpace) ^ 0
grammar[:Delimiter] = "\"" + "[" + "]" + "(" + ")" + :WhiteSpace

# Booleans
grammar[:Boolean] = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false
nativeTypes[typename(Bool)] = :Boolean
evaluators[:Boolean] = (expr, env) -> expr
serializers[:Boolean] = expr -> expr ? "true" : "false"
# Integers
grammar[:Integer] = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i) # matches an chars in between 0-9 with one leading '-' or '+' and convert that to an Integer
nativeTypes[typename(Int64)] = :Integer
evaluators[:Integer] = (expr, env) -> expr
serializers[:Integer] = expr -> string(expr)
# Strings
grammar[:StringEscapes] = "\\\"" + "\\\\" + "\\n" + "\\r" + "\\t" # all the escape pattern we support
grammar[:String] = "\"" * c((:StringEscapes + (1 - ("\"" + "\\"))) ^ 0) * "\"" # match the escape pattern or any char except " or \ (so we only support the listed escape sequences)
nativeTypes[typename(String)] = :String
evaluators[:String] = (expr, env) -> expr
serializers[:String] = expr -> "\"$expr\""
# Arrays
grammar[:Array] = "[" * ca(p(:Expression) ^ 0) * "]" 
nativeTypes[typename(Array)] = :Array
evaluators[:Array] = (array, env) -> map(item -> eval(item, env), array)
serializers[:Array] = array -> string("[", join(map(serialize, array), " "), "]")
# Symbols
grammar[:Symbol] = c((p(1) - :Delimiter) ^ 1) / symbol -> Symbol(symbol)
nativeTypes[typename(Symbol)] = :Symbol
evaluators[:Symbol] = (symbol, env) -> getVar(env, symbol)
serializers[:Symbol] = symbol -> string(symbol)
# Application
grammar[:Application] = "(" * ca(p(:Expression) ^ 1) * ")" / array -> PersistentVector{Any}(array)
nativeTypes[typename(PersistentVector)] = :Application
evaluators[:Application] = (app, env) -> length(app) > 1 ? apply(eval(app[1], env), app[2:end], env) : apply(eval(app[1], env), (), env)
serializers[:Application] = app -> string("(", join(map(serialize, app), " "), ")")

serializers[:PrimitiveFunction] = fun -> string(Symbol(fun))


globalEnviroment = Environment(Dict(), nothing)

function evalArgs(args, env::Environment)
    map(item -> eval(item, env), args)
end

macro definePrimitiveFun(name, fun, inEnv::Environment = globalEnviroment)
    return :(setVar!($inEnv, $name, function $(Symbol(string("primitive", name)))(args, env) $fun(evalArgs(args, env), env) end))
end

@definePrimitiveFun(:+, (args, env) -> foldl(+, args, init=0))
@definePrimitiveFun(:-, (args, env) -> length(args) > 0 ? foldl(-, args) : 0)
@definePrimitiveFun(:*, (args, env) -> foldl(*, args, init=1))
@definePrimitiveFun(:/, (args, env) -> length(args) > 0 ? foldl(/, args) : 1)

macro defSpecialForm(name, fun, inEnv::Environment = globalEnviroment)
    return :(setVar!($inEnv, $name, function $(Symbol(string("special", name)))(args, env) $fun(args, env) end))
end

@defSpecialForm(:def, 
function (args, env) 
    if length(args) != 2
        throw(error("def needs 2 arguments. The var and the value for the var"))
    end
    if typeof(args[1]) !== Symbol
        throw(error("$(args[1]) is not a symbol"))
    end
    setVar!(env, args[1], eval(args[2], env))
end)
    
end
