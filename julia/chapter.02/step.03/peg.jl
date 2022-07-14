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
