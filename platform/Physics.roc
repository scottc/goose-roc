import Host

Physics := {}.
{
    BodyDef : Host.BodyDef

    world_create! : F32, F32 => Try(U64, [PhysErr(Str)])
    world_create! = |gx, gy| Host.phys_world_create!(gx, gy)

    world_step! : U64, F32 => Try({}, [PhysErr(Str)])
    world_step! = |w, dt| Host.phys_world_step!(w, dt)

    world_destroy! : U64 => Try({}, [PhysErr(Str)])
    world_destroy! = |w| Host.phys_world_destroy!(w)

    body_create! : U64, Host.BodyDef => Try(U64, [PhysErr(Str)])
    body_create! = |w, def| Host.phys_body_create!(w, def)

    body_destroy! : U64 => Try({}, [PhysErr(Str)])
    body_destroy! = |b| Host.phys_body_destroy!(b)

    body_set_transform! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
    body_set_transform! = |b, x, y, a| Host.phys_body_set_transform!(b, x, y, a)

    body_get_transform! : U64 => Try({ x: F32, y: F32, angle: F32 }, [PhysErr(Str)])
    body_get_transform! = |b| Host.phys_body_get_transform!(b)

    body_set_velocity! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
    body_set_velocity! = |b, vx, vy, w| Host.phys_body_set_velocity!(b, vx, vy, w)

    body_get_velocity! : U64 => Try({ vx: F32, vy: F32, omega: F32 }, [PhysErr(Str)])
    body_get_velocity! = |b| Host.phys_body_get_velocity!(b)
}
