package main
import m "core:math/linalg"
import rl "vendor:raylib"

// HSV represents a color in HSV color space
HSV :: struct {
    h, s, v: f32,
}

// hsv_to_rgb converts HSV color to RGB color
hsv_to_rgb :: proc(hsv: HSV) -> rl.Color {
    c := hsv.v * hsv.s
    x := c * (1 - m.abs(m.mod(hsv.h / 60, 2) - 1))
    m := hsv.v - c

    r, g, b: f32
    switch {
    case hsv.h < 60:
        r, g, b = c, x, 0
    case hsv.h < 120:
        r, g, b = x, c, 0
    case hsv.h < 180:
        r, g, b = 0, c, x
    case hsv.h < 240:
        r, g, b = 0, x, c
    case hsv.h < 300:
        r, g, b = x, 0, c
    case:
        r, g, b = c, 0, x
    }

    return rl.Color{
        u8((r + m) * 255),
        u8((g + m) * 255),
        u8((b + m) * 255),
        255,
    }
}

// rgb_to_hsv converts RGB color to HSV color
rgb_to_hsv :: proc(color: rl.Color) -> HSV {
    r, g, b := f32(color.r) / 255, f32(color.g) / 255, f32(color.b) / 255
    cmax := m.max(r, m.max(g, b))
    cmin :=m.min(r, m.min(g, b))
    diff := cmax - cmin

    h: f32
    if diff == 0 {
        h = 0
    } else {
        switch cmax {
        case r:
            h = 60 * m.mod((g - b) / diff, 6)
        case g:
            h = 60 * ((b - r) / diff + 2)
        case b:
            h = 60 * ((r - g) / diff + 4)
        }
    }

    s := cmax == 0 ? 0 : diff / cmax
    v := cmax

    return HSV{h, s, v}
}

center_render_bounds_offset :: proc(source_rect, dest_rect: rl.Rectangle) -> rl.Vector2 {
    scale_x := dest_rect.width / source_rect.width
    scale_y := dest_rect.height / source_rect.height
    return {
        source_rect.x + (source_rect.width * scale_x) / 2,
        source_rect.y + (source_rect.height * scale_y) / 2,
    }
}

remap_float :: proc(value, in_min, in_max, out_min, out_max: f32) -> f32 {
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)
}