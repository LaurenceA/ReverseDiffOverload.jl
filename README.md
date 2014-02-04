# ReverseDiff

[![Build Status](https://travis-ci.org/LaurenceA/ReverseDiff.jl.png)](https://travis-ci.org/LaurenceA/ReverseDiff.jl)

Reverse mode differentiation for pre-defined functions.

Using reverse mode differentiation is very simple, just call,
```julia
reversediff(function, args...)
```
for instance, to differentiate `f` defined by,
```julia
f(a, b) = begin
    c = a*b
    dot(c, c) + dot(c, b)
end
```
call,
```julia
reversediff(f, randn(2,2), randn(2))
```
which returns,
```julia
(
2x2 Array{Float64,2}:
  4.33149   1.08533 
 -1.10725  -0.277442,

[5.398285319337722,2.271775240362353])
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
testdiff(f, randn(2,2), randn(2))
```
An error will be generated if the gold-standard finite difference our reverse mode differentiation results do not match.
Note that testdiff is only defined for one or two-argument functions.

Troubleshooting
---------------
Of course, things aren't always quite that simple.
There are three common sources of bugs.
First, `reversediff` differentiates with respect to every argument, so every argument should have type ``Float64``, or ``Array{Float64}``. 
Second, the type signature of the function you're trying to differentiate may be too constrained - the function needs to let values of type `Call` propagate through until they reach known functions.  For instance, `f`, defined above had no type constraints.  
Third, you may be trying to use a function whose differential is not yet defined.  
You can provide define new definitions using the macro `@d1`, for one argument functions, or `@d2`, for two argument functions, for instance, to redefine the differentials for `*`, we might use,
```julia
ReverseDiff.@d2(*, d*y', x'*d)
```
Where `x` is the first argument to the function, `y` is the second argument, and `d` is the differential of the objective with respect to the result of the function call.
Note that you can also annotate the types of `x` and `y`, using,
```julia
ReverseDiff.@d2(*, d*y', x'*d, AbstractArray, AbstractArray)
```

