struct Environment
    vars::Dict{Symbol, Any}
    parent::Union{Environment, Nothing}
end

function getVar(env::Union{Environment, Nothing}, var::Symbol)
    if env === nothing
        throw(error("Unbound var: $var"))
    end
    if haskey(env.vars, var)
        return env.vars[var]
    end
    getVar(env.parent, var)
end

function setVar!(env::Environment, var::Symbol, value)
    env.vars[var] = value
end

