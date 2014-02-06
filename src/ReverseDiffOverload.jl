module ReverseDiffOverload
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
diff(d, c::Call) = begin
    @assert c.deps>0
    c.deps -= 1
    c.dval += d
    if c.deps == 0
        dxs = diff_con(c, c.dval, map(value, c.args)...)
        map(diff, dxs, c.args)
    end
    nothing
end

macro d1(f, ds...)
    eval(parse("import Base.($f)"))
    esc(d1(f, ds...))
end
macro d2(f, ds...)
    eval(parse("import Base.($f)"))
    esc(d2(f, ds...))
end
d1(f::Symbol, dx, tx=:Any) = 
    quote
        $f(x::Call) = Call($f, x)
        diff_con(c::Call{Base.function_name($f)}, d, x::$tx) = ($dx,)
    end
d2(f::Symbol, dx, dy, tx=:Any, ty=:Any) = 
    quote
        $f(x::Call, y::Call) = Call($f, x, y)
        $f(x::Call, y) = Call($f, x, y)
        $f(x, y::Call) = Call($f, x, y)
        diff_con(c::Call{Base.function_name($f)}, d, x::$tx, y::$ty) = ($dx, $dy)
    end

#Wrapper
reversediff(f::Function, args...) = begin
    cargs = map(Call, args)
    res = f(cargs...)
    diff(res)
    map(x -> x.dval, cargs)
end


#Differentiation rules.
#Operators
@d2(+, d, d)
@d2(+, sum(d), d, Number, AbstractArray)
@d2(+, d, sum(d), AbstractArray, Number)

@d2(-, d, -d)
@d2(-, sum(d), -d, Number, AbstractArray)
@d2(-, d, -sum(d), AbstractArray, Number)
@d1(-, -d)

@d2(*, d*y', x'*d)
@d2(*, y*d, dot(x, d), AbstractArray, Number)
@d2(*, dot(y, d), x*d, Number, AbstractArray)

@d2(.*, d.*y, d.*x)

@d2(/, d/y', -(y'\x')*(d/y'))
@d2(\, -(x'\d)*(y'/x'), x'\d)

@d2(.^, d.*y.*(x.^(y-1)), d.*log(x).*(x.^y))

@d2(dot, d*y, d*x)
@d1(det, d*det(x)*inv(x)')
@d1(trace, d*eye(size(x)...))
@d1(inv, -(x'\d)/x')
@d1(exp, d.*exp(x))
@d1(sin, d.*cos(x))
@d1(cos, -d.*sin(x))
@d1(ctranspose, ctranspose(d))
@d1(first, (tmp = zeros(size(x)); tmp[1] = d; tmp))
@d1(vec, reshape(d, size(x)...))
@d1(sum, d*ones(size(x)))

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
