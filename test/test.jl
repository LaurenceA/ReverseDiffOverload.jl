using ReverseDiff
using Calculus

import Base.isapprox
isapprox(x::AbstractArray, y::AbstractArray) = all(map(isapprox, x, y))
import Base.ones
ones(arg::()) = 1.

gentest(f::Function, x, y) = begin
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
gentest(f::Function, x) = begin
    #ReverseDiff   
    cx = Call(x)
    cf = f(cx)
    diff(cf)
    #Gradients
    (vf, devec) = vectorize(f, x)
    (fdx,) = devec(gradient(vf, vectorize(x)[1]))
    @assert isapprox(cx.dval, fdx)
end
gentest(f::String, x) = begin
    println(f)
    gentest(eval(parse("x -> $f")), x)
end
gentest(f::String, x, y) = begin
    println(f)
    gentest(eval(parse("(x, y) -> $f")), x, y)
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
const v1 = randn(2)
const v2 = randn(2)
const v3 = randn(2)
const M  = randn(2, 2)

#dot
gentest("dot(v1, x)", v2)
gentest("dot(x, y)", [1., 2.], [3., 4.])

#+
gentest("x+y", 1., 2.)
gentest("dot(v1, x+y)", 1., v2)
gentest("dot(v1, x+y)", v2, v3)

#-
gentest("x+(-y)", 1., 2.)
gentest("x-y", 1., 2.)
gentest("dot(v1, x-y)", 1., v2)
gentest("dot(v1, -x)", v2)

#*
gentest("x*y", 3., 4.)
gentest("dot(v1, x'*y)", M, v2)
gentest("sum(x*y)", v1', M)
gentest("dot(v1, x*y)", M, v2)

#/
gentest("dot(v1, x\\y)", M, v2)
gentest("dot(v1, vec(x/y))", v2', M)
gentest("x+x*x*exp(x)", 2.)

#'
gentest("first(y'*x*y)", [1. 2;3 4], [5.,6]'')
#matrix funcs
gentest("det(x)", [1. 2;3 4])
gentest("trace(x)", [1. 2;3 4])
gentest("det(inv(x))", [1. 2;3 4])
gentest("sum(x)", [1., 2., 3.])
gentest("dot([1.1, 2.1], vec(x))", [5. 6])

gentest("dot(v1, exp(x))", v2)
gentest("dot(v1, sin(x))", v2)
gentest("dot(v1, cos(x))", v2)

