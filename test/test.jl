using ReverseDiff

const v1 = randn(2)
const v2 = randn(2)
const v3 = randn(2)
const M  = randn(2, 2)

import ReverseDiff.testdiff
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
testdiff("dot(v1, x+y)", 1., v2)
testdiff("dot(v1, x+y)", v2, v3)

#-
testdiff("x+(-y)", 1., 2.)
testdiff("x-y", 1., 2.)
testdiff("dot(v1, x-y)", 1., v2)
testdiff("dot(v1, -x)", v2)

#*
testdiff("x*y", 3., 4.)
testdiff("dot(v1, x'*y)", M, v2)
testdiff("sum(x*y)", v1', M)
testdiff("dot(v1, x*y)", M, v2)

#/
testdiff("dot(v1, x\\y)", M, v2)
testdiff("dot(v1, vec(x/y))", v2', M)
testdiff("x+x*x*exp(x)", 2.)

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

