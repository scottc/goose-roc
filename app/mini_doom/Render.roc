import Palette

## CPU framebuffer: RGB888 packed List(U8), row-major.
Render := {}.
{
    W : U64
    # use literals in code — avoid module const syntax issues
    # 320 x 200

    ## Empty black buffer length = w*h*3
    alloc_rgb : U64, U64 -> List(U8)
    alloc_rgb = |w, h| {
        alloc_rgb_go(w * h * 3, 0, [])
    }

    alloc_rgb_go : U64, U64, List(U8) -> List(U8)
    alloc_rgb_go = |n, i, out| {
        if i >= n {
            out
        } else {
            alloc_rgb_go(n, i + 1, List.append(out, 0))
        }
    }

    ## Set pixel (x,y). No-op if OOB (returns same list).
    set_rgb : List(U8), U64, U64, U64, U64, U8, U8, U8 -> List(U8)
    set_rgb = |buf, w, h, x, y, r, g, b| {
        if x >= w {
            buf
        } else if y >= h {
            buf
        } else {
            i = (y * w + x) * 3
            buf
                |> list_set(i, r)
                |> list_set(i + 1, g)
                |> list_set(i + 2, b)
        }
    }

    list_set : List(U8), U64, U8 -> List(U8)
    list_set = |xs, i, v| {
        # rebuild — fine for smoke; optimize later
        list_set_go(xs, i, v, 0, [])
    }

    list_set_go : List(U8), U64, U8, U64, List(U8) -> List(U8)
    list_set_go = |xs, i, v, j, out| {
        if j >= List.len(xs) {
            out
        } else {
            match List.get(xs, j) {
                Err(_) => out
                Ok(old) => {
                    byte =
                        if j == i {
                            v
                        } else {
                            old
                        }
                    list_set_go(xs, i, v, j + 1, List.append(out, byte))
                }
            }
        }
    }

    ## Fill entire buffer with one PLAYPAL color index.
    fill_index : List(U8), List(U8), U64, U64, U64 -> Try(List(U8), [WadErr(Str)])
    fill_index = |buf, playpal, w, h, ci| {
        match Palette.rgb_at(playpal, ci) {
            Err(e) => Err(e)
            Ok(c) => Ok(fill_rgb(buf, w, h, 0, c.r, c.g, c.b))
        }
    }

    fill_rgb : List(U8), U64, U64, U64, U8, U8, U8 -> List(U8)
    fill_rgb = |buf, w, h, i, r, g, b| {
        n = w * h
        if i >= n {
            buf
        } else {
            x = i % w
            y = i // w
            next = set_rgb(buf, w, h, x, y, r, g, b)
            fill_rgb(next, w, h, i + 1, r, g, b)
        }
    }

    ## Stamp 64×64 flat (palette indices) at top-left, scaled 2× → 128×128.
    blit_flat2x :
        List(U8),
        List(U8),
        List(U8),
        U64,
        U64
        -> Try(List(U8), [WadErr(Str)])
    blit_flat2x = |buf, playpal, flat, w, h| {
        blit_flat2x_go(buf, playpal, flat, w, h, 0)
    }

    blit_flat2x_go :
        List(U8),
        List(U8),
        List(U8),
        U64,
        U64,
        U64
        -> Try(List(U8), [WadErr(Str)])
    blit_flat2x_go = |buf, playpal, flat, w, h, i| {
        if i >= 64 * 64 {
            Ok(buf)
        } else {
            fx = i % 64
            fy = i // 64
            match List.get(flat, i) {
                Err(_) => Err(WadErr("flat pixel"))
                Ok(ci) => {
                    match Palette.rgb_at(playpal, ci.to_u64()) {
                        Err(e) => Err(e)
                        Ok(c) => {
                            x0 = fx * 2
                            y0 = fy * 2
                            b1 = set_rgb(buf, w, h, x0, y0, c.r, c.g, c.b)
                            b2 = set_rgb(b1, w, h, x0 + 1, y0, c.r, c.g, c.b)
                            b3 = set_rgb(b2, w, h, x0, y0 + 1, c.r, c.g, c.b)
                            b4 = set_rgb(b3, w, h, x0 + 1, y0 + 1, c.r, c.g, c.b)
                            blit_flat2x_go(b4, playpal, flat, w, h, i + 1)
                        }
                    }
                }
            }
        }
    }

    ## Very cheap “sky + floor” split for smoke (no raycast yet).
    draw_backdrop : List(U8), List(U8), U64, U64, U64, U64 -> Try(List(U8), [WadErr(Str)])
    draw_backdrop = |buf, playpal, w, h, sky_ci, floor_ci| {
        match Palette.rgb_at(playpal, sky_ci) {
            Err(e) => Err(e)
            Ok(sky) => {
                match Palette.rgb_at(playpal, floor_ci) {
                    Err(e) => Err(e)
                    Ok(fl) => Ok(draw_backdrop_go(buf, w, h, 0, sky, fl))
                }
            }
        }
    }

    draw_backdrop_go :
        List(U8),
        U64,
        U64,
        U64,
        Palette.Rgb,
        Palette.Rgb
        -> List(U8)
    draw_backdrop_go = |buf, w, h, i, sky, fl| {
        n = w * h
        if i >= n {
            buf
        } else {
            x = i % w
            y = i // w
            c =
                if y < h // 2 {
                    sky
                } else {
                    fl
                }
            next = set_rgb(buf, w, h, x, y, c.r, c.g, c.b)
            draw_backdrop_go(next, w, h, i + 1, sky, fl)
        }
    }
}
