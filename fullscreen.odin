package main
import rl "vendor:raylib"
import m  "core:math/linalg/hlsl"
import    "core:fmt"
import    "base:runtime"

set_window_parameters :: proc(screen_width, screen_height : i32, screen_params : ^rl.Vector2) {

    // if linux

    when ODIN_OS == .Linux {
        if (rl.IsKeyPressed(rl.KeyboardKey.ENTER) && (rl.IsKeyDown(rl.KeyboardKey.LEFT_ALT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_ALT))) {
            display := rl.GetCurrentMonitor()
            if (rl.IsWindowFullscreen()) {
                rl.ToggleFullscreen()
                rl.SetWindowSize(screen_width, screen_height)
                screen_params^ = rl.Vector2{f32(screen_width), f32(screen_height)}
    
            }
            else {
                width := rl.GetMonitorWidth(display) * 2
                height := rl.GetMonitorHeight(display) * 2
                rl.SetWindowSize(width, height);
                rl.ToggleFullscreen()
                screen_params^ = rl.Vector2{f32(width), f32(height)}
            }
            rl.SetWindowMonitor(display)
        } 
    } else when ODIN_OS == .Windows {
        if (rl.IsKeyPressed(rl.KeyboardKey.ENTER) && (rl.IsKeyDown(rl.KeyboardKey.LEFT_ALT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_ALT))) {
            display := rl.GetCurrentMonitor()
            if (rl.IsWindowFullscreen()) {
                rl.ToggleFullscreen()
                rl.SetWindowSize(screen_width, screen_height)
                screen_params^ = rl.Vector2{f32(screen_width), f32(screen_height)}
    
            }
            else {
                width := rl.GetMonitorWidth(display)
                height := rl.GetMonitorHeight(display)
                rl.SetWindowSize(width, height);
                rl.ToggleFullscreen()
                screen_params^ = rl.Vector2{f32(width), f32(height)}
            }
            rl.SetWindowMonitor(display)
        } 
    }   
}