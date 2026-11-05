Vec2 := {}.
{
    T : { x : F32, y : F32 }

    zero : T
    zero = { x: 0, y: 0 }

    add : T, T -> T
    add = |a, b| { x: a.x + b.x, y: a.y + b.y }

    sub : T, T -> T
    sub = |a, b| { x: a.x - b.x, y: a.y - b.y }

    scale : T, F32 -> T
    scale = |p, s| { x: p.x * s, y: p.y * s }

    cross : T, T -> F32
    cross = |a, b| a.x * b.y - a.y * b.x

    dot : T, T -> F32
    dot = |a, b| a.x * b.x + a.y * b.y
}
