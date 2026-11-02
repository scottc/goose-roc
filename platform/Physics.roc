module [
    BodyDef,
    world_create!,
    world_step!,
    world_destroy!,
    body_create!,
    body_set_transform!,
    body_get_transform!,
]

import Host

## Subset of Goose/Box3D body creation — expand with shape tags later.
BodyDef : {
    mass : F32,
    x : F32,
    y : F32,
    angle : F32,
    dynamic : Bool,
}

world_create! : F32, F32 => Try(U64, [PhysErr(Str)])
world_create! = |gx, gy| Host.phys_world_create!(gx, gy)

world_step! : U64, F32 => Try({}, [PhysErr(Str)])
world_step! = |world, dt| Host.phys_world_step!(world, dt)

world_destroy! : U64 => Try({}, [PhysErr(Str)])
world_destroy! = |world| Host.phys_world_destroy!(world)

body_create! : U64, BodyDef => Try(U64, [PhysErr(Str)])
body_create! = |world, def| Host.phys_body_create!(world, def)

body_set_transform! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
body_set_transform! = |body, x, y, angle| Host.phys_body_set_transform!(body, x, y, angle)

body_get_transform! : U64 => Try({ x: F32, y: F32, angle: F32 }, [PhysErr(Str)])
body_get_transform! = |body| Host.phys_body_get_transform!(body)
