import Host

Math := {}.
{
    sin! : F64 => Try(F64, [MathErr(Str)])
    sin! = |x| Host.math_sin!(x)

    cos! : F64 => Try(F64, [MathErr(Str)])
    cos! = |x| Host.math_cos!(x)

    tan! : F64 => Try(F64, [MathErr(Str)])
    tan! = |x| Host.math_tan!(x)

    asin! : F64 => Try(F64, [MathErr(Str)])
    asin! = |x| Host.math_asin!(x)

    acos! : F64 => Try(F64, [MathErr(Str)])
    acos! = |x| Host.math_acos!(x)

    atan! : F64 => Try(F64, [MathErr(Str)])
    atan! = |x| Host.math_atan!(x)

    atan2! : F64, F64 => Try(F64, [MathErr(Str)])
    atan2! = |y, x| Host.math_atan2!(y, x)

    sqrt! : F64 => Try(F64, [MathErr(Str)])
    sqrt! = |x| Host.math_sqrt!(x)

    pow! : F64, F64 => Try(F64, [MathErr(Str)])
    pow! = |b, e| Host.math_pow!(b, e)

    exp! : F64 => Try(F64, [MathErr(Str)])
    exp! = |x| Host.math_exp!(x)

    log! : F64 => Try(F64, [MathErr(Str)])
    log! = |x| Host.math_log!(x)

    floor! : F64 => Try(F64, [MathErr(Str)])
    floor! = |x| Host.math_floor!(x)

    ceil! : F64 => Try(F64, [MathErr(Str)])
    ceil! = |x| Host.math_ceil!(x)

    abs! : F64 => Try(F64, [MathErr(Str)])
    abs! = |x| Host.math_abs!(x)
}
