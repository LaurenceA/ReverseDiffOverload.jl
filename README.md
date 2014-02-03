# ReverseDiff

[![Build Status](https://travis-ci.org/LaurenceA/ReverseDiff.jl.png)](https://travis-ci.org/LaurenceA/ReverseDiff.jl)

Reverse mode differentiation for pre-defined functions.

Using reverse mode differentiation is very simple, just call,
```julia
reversediff(function, args...)
```
for instance, to differentiate a dot product, you might use,
```julia
reversediff(dot, [1., 2.], [2., 3.])
```
which returns,
```julia
([3., 4.], [1., 2.])
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
testdiff(dot, [1., 2.], [2., 3.])
```
An error will be generated if the gold-standard finite difference our reverse mode differentiation results do not match.

Troubleshooting
---------------
Of course, things aren't always quite that simple.
There are three common sources of bugs.
First, `reversediff` differentiates with respect to every argument, so every argument should have type ``Float64``, or ``Array{Float64}``. 
Second, the type signature of the function you're trying to differentiate may be too constrained - the function needs to let values of type `Call` propagate through until they reach known functions.
Third, you may be trying to use a function whose differential is not yet defined.  
You can provide define new definitions using the macro `@d`, for instance, to redefine `*`, we would use,
```julia
ReverseDiff.@d(*, d*y', x'*d)
```
Where `x` is the first argument to the function, `y` is the second argument, and `d` is the differential of the objective with respect to the result of the function call.
Note that `ReverseDiff.@d`, like `testdiff` is only implemented for one and two argument functions, though ``reversediff` works with any number of arguments.
