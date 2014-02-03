module ReverseDiff
using Calculus

export reversediff, testdiff

type Call{f, T, As <: Tuple}
    deps::Int
    val::T
    dval::T
    args::As
    Call(val) = new(0, val, zero(val))
    Call(val, args) = new(0, val, zero(val), args)
end
Call(f::Function, args...) = begin
    val = float(f(map(init_value, args)...))
    Call{Base.function_name(f), typeof(val), typeof(args)}(val, args)
end
init_value(v::Call) = begin
    v.deps += 1
    v.val
end
init_value(x) = x
Call(val) = begin
    fval = float(val)
    Call{Nothing, typeof(fval), ()}(fval)
end

value(v::Call) = v.val
value(x) = x

diff(dval, c::Call{Nothing}) = begin
    c.dval += dval
end
diff(dval, val) = nothing

diff(c::Call) = begin
    c.deps += 1
    diff(ones(size(value(c))), c)
end

macro d(f, ds...)
    eval(parse("import Base.$f"))
    esc(d(f, ds...))
end
d(f::Symbol, dx) = 
    quote
        $f(x::Call) = Call($f, x)
        diff{RT, XT}(d, c::Call{Base.function_name($f), RT, (XT,)}) = begin
            @assert c.deps>0
            c.deps -= 1
            c.dval += d
            if c.deps == 0
                d = c.dval
                cx = c.args[1]
                x = value(cx)
                diff($dx, cx)
            end
        end
    end
d(f::Symbol, dx, dy) = 
    quote
        $f(x::Call, y::Call) = Call($f, x, y)
        $f(x::Call, y) = Call($f, x, y)
        $f(x, y::Call) = Call($f, x, y)
        diff{RT, XT, YT}(d, c::Call{Base.function_name($f), RT, (XT, YT)}) = begin
            @assert c.deps>0
            c.deps -= 1
            c.dval += d
            if c.deps == 0
                d = c.dval
                (cx, cy) = (c.args[1], c.args[2])
                (x, y) = (value(cx), value(cy))
                diff($dx, cx)
                diff($dy, cy)
            end
        end
    end

#Wrapper
reversediff(f::Function, args...) = begin
    cargs = map(Call, args)
    res = f(cargs...)
    diff(res)
    map(x -> x.dval, cargs)
end


#Differentiation rules.
@d(+, plus_diff(d, x), plus_diff(d, y))
plus_diff(d::AbstractArray, x::Number) = sum(d)
plus_diff{T}(d::T, x::T) = d

@d(-, plus_diff(d, x), -plus_diff(d, y))
@d(-, -d)

@d(*, d*y', x'*d)
@d(/, d/y', -(y'\x')*(d/y'))
@d(\, -(x'\d)*(y'/x'), x'\d)

@d(dot, d*y, d*x)
@d(det, d*det(x)*inv(x)')
@d(trace, d*eye(size(x)...))
@d(inv, -(x'\d)/x')
@d(exp, d.*exp(x))
@d(sin, d.*cos(x))
@d(cos, -d.*sin(x))
@d(ctranspose, ctranspose(d))
@d(first, (tmp = zeros(size(x)); tmp[1] = d; tmp))
@d(vec, reshape(d, size(x)...))
@d(sum, d*ones(size(x)))

#Testing code
import Base.isapprox
isapprox(x::AbstractArray, y::AbstractArray) = all(map(isapprox, x, y))
import Base.ones
ones(arg::()) = 1.

testdiff(f::Function, x, y) = begin
    #ReverseDiff   
    cx = Call(x)
    cy = Call(y)
    cf = f(cx, cy)
    diff(cf)
    #Gradients
    (vf, devec) = vectorize(f, x, y)
    (fdx, fdy) = devec(gradient(vf, vectorize((x, y))[1]))
    @assert isapprox(cx.dval, fdx)
    @assert isapprox(cy.dval, fdy)
end
testdiff(f::Function, x) = begin
    #ReverseDiff   
    cx = Call(x)
    cf = f(cx)
    diff(cf)
    #Gradients
    (vf, devec) = vectorize(f, x)
    (fdx,) = devec(gradient(vf, vectorize(x)[1]))
    @assert isapprox(cx.dval, fdx)
end

vectorize(a::Float64) = 
    (Float64[a], a::Vector{Float64} -> a[1])
vectorize(a::Vector{Float64}) = 
    (a, identity)
vectorize(a::Matrix{Float64}) = 
    (reshape(a, size(a, 1)*size(a, 2)), v -> reshape(v, size(a, 1), size(a, 2)))
vectorize(args::Tuple) = begin
    vdvs = map(vectorize, args)
    vector = vcat(map(x -> x[1], vdvs)...) 
    #Construct devectorize function
    sizes = map(x -> length(x[1]), vdvs)
    ranges = Range1{Int}[]
    push!(ranges, 1:sizes[1])
    for i = 2:length(sizes)
        push!(ranges, (last(ranges[end])+1):(last(ranges[end])+sizes[i]))
    end
    f = vs::Vector{Float64} -> map((vdv, r) -> vdv[2](vs[r]), vdvs, ranges)
    (vector, f)
end
vectorize(f::Function, args...) = begin
    (vargs, devec) = vectorize(args)
    (v::Vector{Float64} -> f(devec(v)...), devec)
end
end
