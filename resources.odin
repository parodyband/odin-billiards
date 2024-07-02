package main

import      "core:bytes"
import rl   "vendor:raylib"

TextureData :: enum {
    icon,
    sprite_sheet,
}

TEXTURE_DATA := [TextureData][]byte{
    .icon = #load("resources/icon.png"),
    .sprite_sheet = #load("resources/sprite_sheet.png"),
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