module ReverseDiff

export Call, value, diff

type Call{f, T, As <: Tuple}
    computed_diff::Bool
    val::T
    dval::T
    args::As
    Call(val) = new(false, val, zero(val))
    Call(val, args) = new(false, val, zero(val), args)
end
Call(f::Function, args...) = begin
    val = float(f(map(value, args)...))
    Call{Base.function_name(f), typeof(val), typeof(args)}(val, args)
end
Call(val) = begin
    fval = float(val)
    Call{Nothing, typeof(fval), ()}(fval)
end

for op in [+, -, *, /]
    op(x::Call, y::Call) = Call(op, x, y)
    op(x, y::Call) = Call(op, x, y)
    op(x::Call, y) = Call(op, x, y)
end

value(v::Call) = v.val
value(x) = x

diff(dval, c::Call{Nothing}) = begin
    @assert !c.computed_diff
    c.computed_diff=true
    c.dval = dval
end

macro d(f, ds...)
    eval(parse("import Base.$f"))
    esc(d(f, ds...))
end
d(f::Symbol, dx) = 
    quote
        $f(x::Call) = Call($f, x)
        diff(d, c::Call{Base.function_name($f)}) = begin
            @assert !c.computed_diff
            c.computed_diff=true
            x = value(c.args[1])
            diff($dx, c.args[1])
            c.dval = d
        end
    end
d(f::Symbol, dx, dy) = 
    quote
        $f(x::Call, y::Call) = Call($f, x, y)
        $f(x::Call, y) = Call($f, x, y)
        $f(x, y::Call) = Call($f, x, y)
        diff(d, c::Call{Base.function_name($f)}) = begin
            @assert !c.computed_diff
            c.computed_diff=true
            x = value(c.args[1])
            y = value(c.args[2])
            diff($dx, c.args[1])
            diff($dy, c.args[2])
            c.dval = d
        end
    end
#Differentiation rules.
@d(+, d, d)
@d(-, d, -d)
@d(*, d*y', x'*d)
@d(dot, d*y, d*x)
#@d(x/y, y'*d, x'*d)
@d(exp, d.*exp(x))
@d(sin, d.*cos(x))
@d(cos, -d.*sin(x))
end
