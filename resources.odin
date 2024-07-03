package main

import "core:bytes"
import rl "vendor:raylib"
import fmt "core:fmt"

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
    ball_shader_frag,
    ball_shader_vert,
}

SoundData :: enum {
    strike1,
    strike2,
    strike3,
    strike4,
    strike5,
    strike6,
    pocket,
    side_hit1,
    side_hit2,
    hit1,
    hit2,
    hit3,
    hit4,
    hit5,
    rack,
}

FontData :: enum {
    romulus,
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
    .ball_shader_frag = #load("resources/shaders/ball_shader.frag"),
    .ball_shader_vert = #load("resources/shaders/ball_shader.vert"),
}

SOUND_DATA := [SoundData][]byte{
    .strike1 = #load("resources/sounds/strike_1.wav"),
    .strike2 = #load("resources/sounds/strike_2.wav"),
    .strike3 = #load("resources/sounds/strike_3.wav"),
    .strike4 = #load("resources/sounds/strike_4.wav"),
    .strike5 = #load("resources/sounds/strike_5.wav"),
    .strike6 = #load("resources/sounds/strike_6.wav"),
    .pocket = #load("resources/sounds/pocket.wav"),
    .side_hit1 = #load("resources/sounds/side hit 1.wav"),
    .side_hit2 = #load("resources/sounds/side hit 2.wav"),
    .hit1 = #load("resources/sounds/hit_1.wav"),
    .hit2 = #load("resources/sounds/hit_2.wav"),
    .hit3 = #load("resources/sounds/hit_3.wav"),
    .hit4 = #load("resources/sounds/hit_4.wav"),
    .hit5 = #load("resources/sounds/hit_5.wav"),
    .rack = #load("resources/sounds/rack.wav"),
}

FONT_DATA := [FontData][]byte{
    .romulus = #load("resources/fonts/Roboto-Black.ttf"),
}

strike_sound_pool   : AudioPool
hit_sound_pool      : AudioPool
side_hit_sound_pool : AudioPool
rack_sound_pool     : AudioPool
pocket_sound_pool   : AudioPool

default_font : rl.Font

init_sounds :: proc() {
    strike_sound_pool = AudioPool{
        sounds = {
            load_sound_from_embedded(SoundData.strike1),
            load_sound_from_embedded(SoundData.strike2),
            load_sound_from_embedded(SoundData.strike3),
            load_sound_from_embedded(SoundData.strike4),
            load_sound_from_embedded(SoundData.strike5),
            load_sound_from_embedded(SoundData.strike6),
        },
    }
    hit_sound_pool = AudioPool{
        sounds = {
            load_sound_from_embedded(SoundData.hit1),
            load_sound_from_embedded(SoundData.hit2),
            load_sound_from_embedded(SoundData.hit3),
            load_sound_from_embedded(SoundData.hit4),
            load_sound_from_embedded(SoundData.hit5),
        },
    }
    side_hit_sound_pool = AudioPool{
        sounds = {
            load_sound_from_embedded(SoundData.side_hit1),
            load_sound_from_embedded(SoundData.side_hit2),
        },
    }
    rack_sound_pool = AudioPool{
        sounds = {
            load_sound_from_embedded(SoundData.rack),
        },
    }
    pocket_sound_pool = AudioPool{
        sounds = {
            load_sound_from_embedded(SoundData.pocket),
        },
    }
}

get_texture_data :: proc(texture: TextureData) -> []byte {
    return TEXTURE_DATA[texture]
}

get_shader_data :: proc(shader: ShaderData) -> []byte {
    return SHADER_DATA[shader]
}

get_sound_data :: proc(sound: SoundData) -> []byte {
    return SOUND_DATA[sound]
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

load_shader_from_embedded :: proc(vert_shader: ShaderData, frag_shader: ShaderData) -> rl.Shader {
    vertert_data := get_shader_data(vert_shader)
    frag_data := get_shader_data(frag_shader)
    if len(vertert_data) == 0 || len(frag_data) == 0{
        return {}
    }
    return rl.LoadShaderFromMemory(cstring(raw_data(frag_data)), cstring(raw_data(vertert_data)))
}

load_sound_from_embedded :: proc(sound: SoundData) -> rl.Sound {
    data := get_sound_data(sound)
    if len(data) == 0 {
        return {}
    }
    
    wave := rl.LoadWaveFromMemory(".wav", raw_data(data), i32(len(data)))
    defer rl.UnloadWave(wave)
    
    return rl.LoadSoundFromWave(wave)
}

load_font_from_embedded :: proc(font: FontData) -> rl.Font {
    data := FONT_DATA[font]
    fmt.printfln("Embedded font data length: %d", len(data))
    
    if len(data) == 0 {
        fmt.println("No embedded font data found")
        return {}
    }
    
    font_size : i32 = 32  // You can adjust this size as needed
    loaded_font := rl.LoadFontFromMemory(".ttf", raw_data(data), i32(len(data)), font_size, nil, 0)
    
    if loaded_font.texture.id == 0 {
        fmt.println("Failed to load font from embedded data")
        return {}
    }
    
    fmt.printfln("Font created from embedded data: baseSize=%d, glyphCount=%d", loaded_font.baseSize, loaded_font.glyphCount)
    
    return loaded_font
}