# ReverseDiffOverload

[![Build Status](https://travis-ci.org/LaurenceA/ReverseDiffOverload.jl.png)](https://travis-ci.org/LaurenceA/ReverseDiffOverload.jl)

Reverse mode differentiation for pre-defined functions.

Using reverse mode differentiation is very simple, just call,
```julia
reversediff(function, args...)
```
for instance, to differentiate `f`, defined by,
```julia
f(a, b) = begin
    c = a*b
    dot(c, c) + dot(c, b)
end
```
at, `[1. 2; 3 4], [1., 2]`, call,
```julia
reversediff(f, [1. 2; 3 4], [1., 2])
```
which returns a tuple containing the differential of the return value with respect to every argument,
```julia
(
2x2 Array{Float64,2}:
 11.0  22.0
 24.0  48.0,

[88.0,129.0])
```

Testing
-------
It is good practice, at this early stage, to test that `reversediff` produces the correct results for your problem.
To do such a test on your function, simply call,
```julia
testdiff(g, args...)
```
for instance,
```julia
testdiff(f, [1. 2; 3 4], [1., 2])
```
An error will be generated if finite difference and our method give different results.
Note that testdiff is only defined for one or two-argument functions.

Troubleshooting
---------------
Of course, things aren't always quite that simple.
There are three common sources of bugs.
First, `reversediff` differentiates with respect to every argument, so every argument should have type `Float64`, or ``Array{Float64}``.  Notice the care taken in the example to make sure that we don't get an array of `Int`.  Second, the type signature of the function you're trying to differentiate may be too constrained - the function needs to let values of type `Call` propagate through until they reach known functions.  Notice, `f`, defined above had no type constraints.  Third, you may be trying to use a function whose differential is not yet defined.  You can provide define new definitions using the macro `@d1`, for one argument functions, or `@d2`, for two argument functions, for instance, to redefine the differentials for `*`, we might use,
```julia
ReverseDiff.@d2(*, d*y', x'*d)
```
Where `x` is the first argument to the function, `y` is the second argument, and `d` is the differential of the objective with respect to the result of the function call.  Note that you can also annotate the types of `x` and `y`, using,
```julia
ReverseDiff.@d2(*, d*y', x'*d, AbstractArray, AbstractArray)
```

