using ReverseDiff
using Calculus

import Base.isapprox
isapprox(x::AbstractArray, y::AbstractArray) = all(map(isapprox, x, y))
import Base.ones
ones(arg::()) = 1.

macro gentest(args...)
    esc(gentest(args...))
end
gentest(f, x, y) = quote
        println(($f, $x, $y))
        #ReverseDiff   
        cx = Call($x)
        cy = Call($y)
        cf = $f(cx, cy)
        diff(ones(size(value(cf))), cf)
        #Gradients
        (vf, devec) = vectorize($f, $x, $y)
        (fdx, fdy) = devec(gradient(vf, vectorize(($x, $y))[1]))
        @assert isapprox(cx.dval, fdx)
        @assert isapprox(cy.dval, fdy)
    end
gentest(f, x) = quote
        println(($f, $x))
        #ReverseDiff   
        cx = Call($x)
        cf = $f(cx)
        diff(ones(size(value(cf))), cf)
        #Gradients
        (vf, devec) = vectorize($f, $x)
        (fdx,) = devec(gradient(vf, vectorize($x)[1]))
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


        
@gentest(+, 1., 2.)
@gentest((a, b) -> dot([1.1, 1.3], a+b), ones(2), 2*ones(2))
@gentest(*, 3., 4.)
@gentest(dot, [1., 2.], [3., 4.])
@gentest((a, b) -> dot([1.1, 1.3], a*b), [1. 2;3 4], [5.,6])
@gentest(det, [1. 2;3 4])
@gentest(trace, [1. 2;3 4])
@gentest((a, b) -> dot([1.1, 1.3], a\b), [1. 2;3 4], [5.,6])
@gentest((a, b) -> dot([1.1, 1.3], a'*b), [1. 2;3 4], [5.,6])
@gentest(sum, [1., 2., 3.])
@gentest(a -> dot([1.1, 2.1], vec(a)), [5. 6])
@gentest((a, b) -> sum(a*b), [5. 6], [1. 2;3 4])
@gentest(exp, 1.)
@gentest(a -> dot([1.1, 1.3], sin(a)), [0, pi/2.])
@gentest(a -> dot([1.1, 1.3], cos(a)), [0, pi/2.])

