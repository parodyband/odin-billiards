package main

import      "core:bytes"
import rl   "vendor:raylib"

TextureData :: enum {
    icon,
    sprite_sheet,
    ball_1,
    ball_2,
    ball_3,
    ball_4,
    ball_5,
    ball_6,
    ball_7,
    ball_8,
    ball_9,
    ball_10,
    ball_11,
    ball_12,
    ball_13,
    ball_14,
    ball_15,
    ball_16,
}

ShaderData :: enum {
    ball_shader
}

TEXTURE_DATA := [TextureData][]byte{
    .icon = #load("resources/icon.png"),
    .sprite_sheet = #load("resources/sprite_sheet.png"),
    .ball_1 = #load("resources/balls/ball_1.png"),
    .ball_2 = #load("resources/balls/ball_2.png"),
    .ball_3 = #load("resources/balls/ball_3.png"),
    .ball_4 = #load("resources/balls/ball_4.png"),
    .ball_5 = #load("resources/balls/ball_5.png"),
    .ball_6 = #load("resources/balls/ball_6.png"),
    .ball_7 = #load("resources/balls/ball_7.png"),
    .ball_8 = #load("resources/balls/ball_8.png"),
    .ball_9 = #load("resources/balls/ball_9.png"),
    .ball_10 = #load("resources/balls/ball_10.png"),
    .ball_11 = #load("resources/balls/ball_11.png"),
    .ball_12 = #load("resources/balls/ball_12.png"),
    .ball_13 = #load("resources/balls/ball_13.png"),
    .ball_14 = #load("resources/balls/ball_14.png"),
    .ball_15 = #load("resources/balls/ball_15.png"),
    .ball_16 = #load("resources/balls/ball_16.png"),
}

SHADER_DATA := [ShaderData][]byte{
    .ball_shader = #load("resources/shaders/ball_shader.frag"),
}

get_texture_data :: proc(texture: TextureData) -> []byte {
    return TEXTURE_DATA[texture]
}

load_texture_from_embedded :: proc(texture: TextureData) -> rl.Texture2D {
    data := get_texture_data(texture)
    if len(data) == 0 {
        return {}
    }
    
    image := rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
    defer rl.UnloadImage(image)
    
    return rl.LoadTextureFromImage(image)
}

load_image_from_embedded :: proc(texture: TextureData) -> rl.Image {
    data := get_texture_data(texture)
    if len(data) == 0 {
        return {}
    }
    
    return rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
}

load_shader_from_embedded :: proc(shader: ShaderData) -> rl.Shader {
    data := SHADER_DATA[shader]
    if len(data) == 0 {
        return {}
    }
    
    return rl.LoadShader(nil, cstring(raw_data(data)))
}