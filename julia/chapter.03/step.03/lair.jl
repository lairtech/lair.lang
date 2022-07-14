abstract type Pattern end

function pattern(pattern::Pattern)
    pattern
end
            
function match(anyPattern::Any, text::String, i::Integer=1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    match(pattern(anyPattern), text, i, grammar, captureStack)
end

p(anyPattern) = pattern(anyPattern)

struct Literal <: Pattern
    value::String
end

function pattern(literal::String)
    Literal(literal)
end

function match(literal::Literal, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    if length(text) >= i &&  startswith(text[i:end], literal.value)
        i + length(literal.value), nothing
    end
end


struct OrderedChoice <: Pattern
    patterns::Array{Pattern}
end

function match(orderedChoice::OrderedChoice, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    for pattern in orderedChoice.patterns
        result = match(pattern, text, i, grammar, captureStack)
        if result !== nothing
            return result
        end
    end
end

function Base.:(+)(choice1::Any, choice2::Any)
    OrderedChoice([p(choice1), p(choice2)])
end

function Base.:(+)(choice1::OrderedChoice, choice2::Any)
    OrderedChoice(append!(deepcopy(choice1.patterns), [p(choice2)]))
end

function Base.:(+)(choice1::Any, choice2::OrderedChoice)
    OrderedChoice(append!([p(choice1)], choice2.patterns))
end

function Base.:(+)(choice1::OrderedChoice, choice2::OrderedChoice)
    OrderedChoice(append!(deepcopy(choice1.patterns), choice2.patterns))
end

struct Capture <: Pattern
    pattern::Pattern
    type::Symbol
end

function capture(pattern::Pattern)
    Capture(pattern, :string)
end

c(pattern::Pattern) = capture(pattern::Pattern)

function captureArray(pattern::Pattern)
    Capture(pattern, :array)
end

ca(pattern::Pattern) = captureArray(pattern::Pattern)

function match(capture::Pattern, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    start = i
    result = match(capture.pattern, text, i, grammar, []) # new capture stack
    if result === nothing
        return nothing
    end
    index, caputure = result
    if capture.type == :string
        return index, text[start:index-1]
    elseif capture.type == :array
        return index, Array(captureStack)
    end
end

struct Transform <: Pattern
    pattern::Pattern
    fun::Function
end

function match(transform::Transform, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    result = match(transform.pattern, text, i, grammar, captureStack)
    if result === nothing
        return nothing
    end
    index, capture = result
    index, transform.fun(capture)
end
 
function Base.:(/)(pattern::Pattern, fun::Function)
    Transform(pattern, fun)
end

struct CharRange <: Pattern
    min::Char
    max::Char
end

function range(min::Char, max::Char)
    CharRange(min, max)
end

function match(charRange::CharRange, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    if length(text) >= i && text[i] >= charRange.min && text[i] <= charRange.max
        i+1, nothing
    end
end

struct Repeat <: Pattern
    pattern::Pattern
    count::Integer
end

@inline function Base.literal_pow(f::typeof(^), pattern::Pattern, ::Val{count}) where {count}
    Repeat(pattern, count)
end

function match(repeat::Repeat, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    count = repeat.count
    index = i
    result = nothing
    if count >= 0
        while count > 0
            result = match(repeat.pattern, text, index, grammar, captureStack)
            if result === nothing
                return nothing
            end
            count = count - 1
            index = result[1]
        end
        while true
            restResult = match(repeat.pattern, text, index, grammar, captureStack)
            if restResult === nothing
                return result === nothing ? (index, nothing) : result
            end
            if restResult[2] !== nothing
                push!(captureStack, restResult[2])
            end
            result = restResult
            index = result[1]
        end
    else 
        while count < 0
            upToResult = match(repeat.pattern, text, index, grammar, captureStack)
            if upToResult === nothing 
                return result === nothing ? (index, nothing) : result
            end
            if upToResult[2] !== nothing
                push!(captureStack, upToResult[2])
            end
            result = upToResult
            index = result[1]
            count = count + 1
        end
    end
    result  
end

          
struct Sequence <: Pattern
    patterns::Array{Pattern}
end

    
function Base.:(*)(pattern1::Any, pattern2::Any)
    Sequence([p(pattern1), p(pattern2)])
end

function Base.:(*)(sequence::Sequence, anyPattern::Any)
    Sequence(append!(deepcopy(sequence.patterns), [p(anyPattern)]))
end

function Base.:(*)(anyPattern::Any, sequence::Sequence)
    Sequence(append!([p(anyPattern)], sequence.patterns))
end

function Base.:(*)(sequence1::Sequence, sequence2::Sequence)
    Sequence(append!(deepcopy(sequence1.patterns), sequence2.patterns))
end

function match(sequence::Sequence, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    result = nothing
    index = i
    capture = nothing
    for pattern in sequence.patterns
        result = match(pattern, text, index, grammar, captureStack)
        if result === nothing
            return nothing
        end
        if result[2] !== nothing
            capture = result[2]
            push!(captureStack, result[2])
        end
        index = result[1]     
    end
    index, capture
end

struct AnyChar <: Pattern
    count::Integer
end

function pattern(anyCharCount::Integer)
    AnyChar(anyCharCount)
end

function match(anyChar::AnyChar, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    if anyChar.count >= 0 && i - 1 + anyChar.count <= length(text)
        return i + anyChar.count, nothing
    elseif anyChar.count < 0 && i - 1 <= length(text) + anyChar.count
        return i, nothing
    end
end

struct Negate <: Pattern
    pattern::Pattern
end

function Base.:(-)(negatePattern::Pattern)
    Negate(negatePattern)
end

function Base.:(-)(anyPattern::Any, negatePattern::Pattern)
    (-negatePattern) * p(anyPattern)
end

function Base.:(-)(anyPattern::Pattern, negatePattern::Any)
    (-p(negatePattern)) * anyPattern
end

function match(negatePattern::Negate, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    if match(negatePattern.pattern, text, i, grammar) === nothing
        i, nothing
    end
end

function parseExpr(input::String)
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

struct Reference <: Pattern
    name::Symbol
end

function pattern(symbol::Symbol)
    Reference(symbol)
end

function match(reference::Reference, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    if grammar !== nothing
        rule = grammar[reference.name]
        if rule !== nothing
            match(rule, text, i, grammar, captureStack)
        end
    end
end

function match(dictGrammar::Dict, text::String, i::Integer = 1, grammar::Union{Dict, Nothing} = nothing, captureStack::Array=[])
    startRuleName = dictGrammar[1]
    if startRuleName !== nothing && dictGrammar[startRuleName] !== missing
        match(dictGrammar[startRuleName], text, i, dictGrammar, captureStack)
    end
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

function evalExpr(expr, env)
    applyExpr(evaluators[typeOf(expr)], expr, env)
end

function applyExpr(applicator, args, env)
    if typeOf(applicator) == :PrimitiveFunction
        applicator(args, env)
    else
        applyExpr(applicators[typeOf(applicator)], append!([applicator], args), env)
    end
end

serializers = Dict()

function serializeExpr(expr)
    serializer = serializers[typeOf(expr)]
    if serializer !== nothing
        return serializer(expr)
    end
end

function printExpr(expr)
    println(serializeExpr(expr))
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
        result  = evalExpr(expr, nothing)
        printExpr(result)
    end
end

grammar = Dict()
grammar[1] = :Expression
grammar[:Expression] = :WhiteSpace * (:Collection + :Atom) * :WhiteSpace
grammar[:Atom] = :Boolean + :Integer + :String
grammar[:Collection] = :Array

grammar[:WhiteSpace] = (" " + "\t" + "\r" + "\n") ^ 0

# Booleans
grammar[:Boolean] = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false
nativeTypes[Bool] = :Boolean
evaluators[:Boolean] = (expr, env) -> expr
serializers[:Boolean] = expr -> expr ? "true" : "false"
# Integers
grammar[:Integer] = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> parse(Int64, i) # matches an chars in between 0-9 with one leading '-' or '+' and convert that to an Integer
nativeTypes[Int64] = :Integer
evaluators[:Integer] = (expr, env) -> expr
serializers[:Integer] = expr -> expr
# Strings
grammar[:StringEscapes] = "\\\"" + "\\\\" + "\\n" + "\\r" + "\\t" # all the escape pattern we support
grammar[:String] = "\"" * c((:StringEscapes + (1 - ("\"" + "\\"))) ^ 0) * "\"" # match the escape pattern or any char except " or \ (so we only support the listed escape sequences)
nativeTypes[String] = :String
evaluators[:String] = (expr, env) -> expr
serializers[:String] = expr -> "\"$expr\""
# Arrays
grammar[:Array] = "[" * ca(p(:Expression) ^ 0) * "]" #/ l -> (l === nothing) ? [] : Array(l) 
nativeTypes[Vector{Any}] = :Array
evaluators[:Array] = (array, env) -> Vector{Any}(map(item -> evalExpr(item, env), array))
serializers[:Array] = array -> string("[", join(map(serializeExpr, array), " "), "]")

match(grammar, "[1]")