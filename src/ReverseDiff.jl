module ReverseDiff

export Call, value, diff

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
        diff(d, c::Call{Base.function_name($f)}) = begin
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
        diff(d, c::Call{Base.function_name($f)}) = begin
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
#Differentiation rules.
@d(+, d, d)
@d(-, d, -d)
@d(*, d*y', x'*d)
@d(dot, d*y, d*x)
@d(det, d*det(x)*inv(x)')
@d(trace, d*eye(size(x)...))

#Guess
#@d(/, y'\d, x'*d)
@d(/, d/y', -(y'\x)*(d/y'))
@d(\, -(x'\d)*(y'/x'), x'\d)
@d(exp, d.*exp(x))
@d(sin, d.*cos(x))
@d(cos, -d.*sin(x))
@d(ctranspose, ctranspose(d))
@d(vec, reshape(d, size(x)...))
@d(sum, d*ones(size(x)))
end
