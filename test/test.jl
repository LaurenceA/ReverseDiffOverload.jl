using ReverseDiffOverload

const v1 = randn(2)
const v2 = randn(2)
const v3 = randn(2)
const M  = randn(2, 2)

import ReverseDiffOverload.testdiff
testdiff(f::String, x) = begin
    println(f)
    testdiff(eval(parse("x -> $f")), x)
end
testdiff(f::String, x, y) = begin
    println(f)
    testdiff(eval(parse("(x, y) -> $f")), x, y)
end
#dot
testdiff("dot(v1, x)", v2)
testdiff("dot(x, y)", [1., 2.], [3., 4.])

#+
testdiff("x+y", 1., 2.)
testdiff("dot(v1, x+y)", v2, v3)
testdiff("dot(v1, x+y)", 1., v2)

#-
testdiff("x+(-y)", 1., 2.)
testdiff("x-y", 1., 2.)
testdiff("dot(v1, x-y)", v2, v3)
testdiff("dot(v1, x-y)", 1., v2)
testdiff("dot(v1, -x)", v2)

#*
testdiff("x*y", 3., 4.)
testdiff("dot(v1, x'*y)", M, v2)
testdiff("sum(x*y)", v1', M)
testdiff("dot(v1, x*y)", M, v2)
testdiff("dot(v1, x*y)", randn(), v2)

#/
testdiff("dot(v1, x\\y)", M, v2)
testdiff("dot(v1, vec(x/y))", v2', M)
testdiff("x+x*x*exp(x)", 2.)

#.^
testdiff("x .^ y", 2.5, 3.5)
testdiff("x .^ y", 2.5, -3.5)
testdiff("dot(v1, x .* y)", v2, v3)
testdiff("dot(v1, x .^ y)", [1., 2.], [3., 4.])

#'
testdiff("first(y'*x*y)", [1. 2;3 4], [5.,6]'')
#matrix funcs
testdiff("det(x)", [1. 2;3 4])
testdiff("trace(x)", [1. 2;3 4])
testdiff("det(inv(x))", [1. 2;3 4])
testdiff("sum(x)", [1., 2., 3.])
testdiff("dot([1.1, 2.1], vec(x))", [5. 6])

testdiff("dot(v1, exp(x))", v2)
testdiff("dot(v1, sin(x))", v2)
testdiff("dot(v1, cos(x))", v2)

testdiff("sum(exp(x.*v1))", v2)

testdiff("sum(x./y)", v2, v3)

testdiff("sum(rectlin(M*x))", v1)
testdiff("logΓ(x)", 3)
testdiff("logΓ(x)", 3)
testdiff("getindex(x, 2)", ones(3))
testdiff("first(v1'*sum(x, 2))", randn(2,2))
testdiff("first(sum(x, 1)*v1)", randn(2,2))
