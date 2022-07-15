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

function extendEnv(env::Environment, vars::Vector{Symbol}, values::Vector)
    if length(vars) != length(values)
        throw(error("Extending enviroment with uneven vars ($vars) and values($values)"))
    end
    extendedEnviroment = Environment(Dict(), env)
    for i in 1:length(vars)
        setVar!(extendedEnviroment, vars[i], values[i])
    end
    extendedEnviroment
end
