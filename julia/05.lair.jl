abstract type Pattern end

function pattern(pattern::Pattern)
    pattern
end
            
function match(anyPattern::Any, text::String, i::Integer=1)
    match(pattern(anyPattern), text, i)
end

p(anyPattern) = pattern(anyPattern)

struct Literal <: Pattern
    value::String
end

function pattern(literal::String)
    Literal(literal)
end

function match(literal::Literal, text::String, i::Integer = 1)
    if length(text) >= i &&  startswith(text[i:end], literal.value)
        i + length(literal.value), nothing
    end
end


struct OrderedChoice <: Pattern
    patterns::Array{Pattern}
end

function match(orderedChoice::OrderedChoice, text::String, i::Integer = 1)
    for pattern in orderedChoice.patterns
        result = match(pattern, text, i)
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
end

function capture(pattern::Pattern)
    Capture(pattern)
end

c(pattern::Pattern) = capture(pattern::Pattern)

function match(capture::Pattern, text::String, i::Integer = 1)
    start = i
    result = match(capture.pattern, text, i)
    if result === nothing
        return nothing
    end
    index, caputure = result
    return index, text[start:index-1]
end

struct Transform <: Pattern
    pattern::Pattern
    fun::Function
end


function match(transform::Transform, text::String, i::Integer = 1)
    result = match(transform.pattern, text, i)
    if result === nothing
        return nothing
    end
    index, capture = result
    if capture !== nothing 
        capture = transform.fun(capture)
    end
    index, capture
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

function match(charRange::CharRange, text::String, i::Integer = 1)
    if length(text) >= i && text[i] >= charRange.min && text[i] <= charRange.max
        i+1, nothing
    end
end

struct Repeat <: Pattern
    pattern::Pattern
    count::Integer
end

function Base.:(%)(pattern::Pattern, count::Integer)
    Repeat(pattern, count)
end

function match(repeat::Repeat, text::String, i::Integer = 1)
    count = repeat.count
    index = i
    result = nothing
    if count >= 0
        while count > 0
            result = match(repeat.pattern, text, index)
            if result === nothing
                return nothing
            end
            count = count - 1
            index = result[1]
        end
        while true
            restResult = match(repeat.pattern, text, index)
            if restResult === nothing
                return result
            end
            result = restResult
            index = result[1]
        end
    else 
        while count < 0
            upToResult = match(repeat.pattern, text, index)
            if upToResult === nothing 
                if result === nothing
                    return index, nothing
                else
                    return result
                end
            end
            result = upToResult
            count = count + 1
            index = result[1]
        end
        result
    end
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

function match(sequence::Sequence, text::String, i::Integer = 1)
    index = i
    result = nothing
    for pattern in sequence.patterns
        result = match(pattern, text, index)
        if result === nothing
            return nothing
        end
        index = result[1]
    end
    result
end

booleanPattern = c("true" + "false") / m -> m == "true" # matches either "true" or "false", caputre it and then transform it on match to boolean true or false
integerPattern = c(("-" + "+") % -1 * range('0', '9') % 1) / i -> parse(Int64, i) # matches an chars in between 0-9 with one leading '-' or '+' and convert that to an Integer
primitivePattern = booleanPattern + integerPattern

function parseExpr(input::String)
    matchedExpr = match(primitivePattern, input)
    if matchedExpr === nothing
        return nothing
    end
    index, capture = matchedExpr
    capture
end

function evalExpr(expr)
    expr
end

function printExpr(expr::Bool)
    if expr == true
        println("true")
    else expr == false
        println("false")
    end
end

function printExpr(expr::Integer)
    println(expr)
end

function printExpr(expr::Any)
    println("Unkown expression: $expr")
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