using ReverseDiff

import Base.isapprox
isapprox(x::AbstractArray, y::AbstractArray) = all(map(isapprox, x, y))
import Base.ones
ones(arg::()) = 1.

macro gentest(args...)
    esc(gentest(args...))
end
gentest(f, x, y, dx, dy) = quote
        cx = Call($x)
        cy = Call($y)
        cf = $f(cx, cy)
        diff(ones(size(value(cf))), cf)
        @assert isapprox(cx.dval, $dx)
        @assert isapprox(cy.dval, $dy)
    end
gentest(f, x, dx) = quote
        cx = Call($x)
        cf = $f(cx)
        diff(ones(size(value(cf))), cf)
        @assert isapprox(cx.dval, $dx)
    end
        
@gentest(+, 1., 2., 1., 1.)
@gentest(+, ones(2), 2*ones(2), ones(2), ones(2))
@gentest(*, 3., 4., 4., 3.)
@gentest(dot, [1, 2], [3, 4], [3, 4], [1, 2])
@gentest(*, [1 2;3 4], [5,6], [5 6;5 6], [4, 6])
@gentest(exp, [0., 1., 2.], [1., exp(1.), exp(2.)])
@gentest(sin, [0, pi/2., pi], [1., 0. , -1])
@gentest(cos, [0, pi/2., pi], [0., -1., 0.])

