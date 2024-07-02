package main

import rl    "vendor:raylib"
import m     "core:math/linalg"
import       "core:math/rand"
import fmt   "core:fmt"
import time  "core:time"
import win32 "core:sys/windows"

// Constants
BALL_SCALE    :: 64
PHYSICS_FPS   :: 60
PHYSICS_DT    :: 1.0 / f32(PHYSICS_FPS)
MIN_VELOCITY  :: 10.0
MAX_VELOCITY  :: 5000.0
FRICTION      :: 0.993
BALL_COUNT    :: 16
RESTITUTION   :: 0.999
FLING_FACTOR  :: 20.0   

// Structs
Table :: struct {
    atlasBounds     : rl.Rectangle,
    collisionBounds : rl.Rectangle,
    position        : rl.Vector2,
}

Ball :: struct {
    atlasBounds                                         : rl.Rectangle,
    position, worldPosition, velocity, previousPosition : rl.Vector2,
    is_dragging                                         : bool,
    drag_start, drag_current                            : rl.Vector2,
}

Cursor :: struct {
    atlasBounds : rl.Rectangle,
    position    : rl.Vector2,
}

GameState :: struct {
    table              : Table,
    cursor             : Cursor,
    balls              : [BALL_COUNT]Ball,
    screen_width       : i32,
    screen_height      : i32,
    sprite_atlas       : rl.Texture2D,
    fullscreen_texture : rl.RenderTexture2D,
    real_screen_params : rl.Vector2,
}

// Global state
game : GameState

main :: proc() {
    init_game()
    defer cleanup()

    for !rl.WindowShouldClose() {
        set_window_parameters(game.screen_width, game.screen_height, &game.real_screen_params)
        update_game()
        draw_game()
    }
}

init_game :: proc() {
    game.screen_width  = 1920
    game.screen_height = 1080
    monitor_id := i32(0)

    rl.InitWindow(game.screen_width, game.screen_height, "Billiards")
    rl.SetWindowIcon(load_image_from_embedded(TextureData.icon))
    rl.SetWindowMonitor(monitor_id)
    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.VSYNC_HINT})
    rl.HideCursor()
    refresh_rate := rl.GetMonitorRefreshRate(monitor_id)
    rl.SetTargetFPS(refresh_rate)

    game.real_screen_params = rl.Vector2{f32(game.screen_width), f32(game.screen_height)}
    game.fullscreen_texture = rl.LoadRenderTexture(game.screen_width, game.screen_height)
    game.sprite_atlas = load_texture_from_embedded(TextureData.sprite_sheet)

    init_data()
}

init_data :: proc() {
    // Table
    game.table = Table{
        atlasBounds     = {0, 0, 224, 128},
        collisionBounds = {23, 23, 178, 82},
        position        = {0, 0},
    }

    tableBounds := rl.Vector2{f32(game.screen_width), f32(game.screen_height)}
    game.table.position = {
        f32(game.screen_width) / 2 - tableBounds.x / 2,
        f32(game.screen_height) / 2 - tableBounds.y / 2,
    }

    // Cursor
    game.cursor = Cursor{
        atlasBounds = {224, 64, 32, 32},
        position    = {0, 0},
    }

    // Balls
    for i := 0; i < BALL_COUNT; i += 1 {
        angle := rand.float32_range(0, 2 * m.PI)
        direction := rl.Vector2{m.cos(angle), m.sin(angle)}
        game.balls[i] = Ball{
            atlasBounds = {237, 13, 22, 22},
            position = {
                f32(game.screen_width) / 2 + f32(i) * f32(BALL_SCALE) * 1.1,
                f32(game.screen_height) / 2,
            },
            velocity = direction * 100,
        }
        game.balls[i].previousPosition = game.balls[i].position
    }
}

cleanup :: proc() {
    rl.UnloadRenderTexture(game.fullscreen_texture)
    rl.UnloadTexture(game.sprite_atlas)
    rl.CloseWindow()
}

update_game :: proc() {
    delta_time := rl.GetFrameTime()
    update_physics(delta_time)
    update_cursor()

    mouse_over_any_ball := false
    for i := 0; i < BALL_COUNT; i += 1 {
        ball := &game.balls[i]
        
        if is_mouse_over_ball(ball) {
            mouse_over_any_ball = true
            
            if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                start_drag(ball)
            }
        }
        
        if ball.is_dragging {
            if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
                ball.drag_current = rl.GetMousePosition()
            } else {
                end_drag(ball)
            }
        }
    }
    
    if !mouse_over_any_ball && rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        for i := 0; i < BALL_COUNT; i += 1 {
            end_drag(&game.balls[i])
        }
    }
}

update_physics :: proc(delta_time: f32) {
    for i := 0; i < BALL_COUNT; i += 1 {
        update_ball(&game.balls[i], delta_time)
    }
    check_balls_collision()
}

update_ball :: proc(ball: ^Ball, delta_time: f32) {
    ball.previousPosition = ball.position
    ball.position += ball.velocity * delta_time
    ball.velocity *= FRICTION
    check_ball_wall_collision(ball)
    check_minimum_velocity(ball)
}

start_drag :: proc(ball: ^Ball) {
    ball.is_dragging = true
    ball.drag_start = rl.GetMousePosition()
    ball.drag_current = ball.drag_start
}

end_drag :: proc(ball: ^Ball) {
    if ball.is_dragging {
        ball.is_dragging = false
        fling_vector := ball.drag_start - ball.drag_current
        drag_distance := m.length(fling_vector)
        
        if drag_distance > 1 {
            fling_strength := clamp(drag_distance * FLING_FACTOR, MIN_VELOCITY, MAX_VELOCITY)
            fling_velocity := m.normalize(fling_vector) * fling_strength
            ball.velocity = fling_velocity
        }
    }
}

update_cursor :: proc() {
    game.cursor.position = rl.GetMousePosition()
}

draw_game :: proc() {
    rl.BeginTextureMode(game.fullscreen_texture)
    rl.ClearBackground(rl.BLACK)
    draw_table()
    draw_balls()

    rl.DrawFPS(10, 10)
    rl.EndTextureMode()

    // Draw fullscreen texture
    rl.BeginDrawing()

    source_rec := rl.Rectangle{
        0,
        0,
        f32(game.fullscreen_texture.texture.width),
        -f32(game.fullscreen_texture.texture.height),
    }
    dest_rec := rl.Rectangle{
        0,
        0,
        game.real_screen_params.x,
        game.real_screen_params.y,
    }

    rl.DrawTexturePro(
        game.fullscreen_texture.texture,
        source_rec,
        dest_rec,
        {0, 0},
        0,
        rl.WHITE
    )

    // Draw cursor
    rl.DrawTexturePro(
        game.sprite_atlas,
        game.cursor.atlasBounds,
        {game.cursor.position.x, game.cursor.position.y, 64, 64},
        {32, 32},
        0,
        rl.WHITE
    )

    rl.EndDrawing()
}

draw_table :: proc() {
    tableBounds := rl.Vector2{f32(game.screen_width), f32(game.screen_height)}
    rl.DrawTexturePro(
        game.sprite_atlas,
        game.table.atlasBounds,
        {0, 0, tableBounds.x, tableBounds.y},
        game.table.position,
        0,
        rl.WHITE
    )
}

draw_balls :: proc() {
    for i := 0; i < BALL_COUNT; i += 1 {
        draw_ball(&game.balls[i])
    }
}

draw_ball :: proc(using ball: ^Ball) {
    new_ball_scale := f32(BALL_SCALE * 1.375)
    dest_rect := rl.Rectangle{position.x - new_ball_scale/2, position.y - new_ball_scale/2, new_ball_scale, new_ball_scale}
    
    ball_color := rl.WHITE
    if is_dragging {
        ball_color = rl.GREEN
    } else if is_mouse_over_ball(ball) {
        ball_color = rl.RED
    }
    
    rl.DrawTexturePro(
        game.sprite_atlas,
        atlasBounds,
        dest_rect,
        {0, 0},
        0,
        ball_color
    )
    
    if is_dragging {
        rl.DrawLineEx(position, drag_current, 2, rl.BLUE)
        
        direction := m.normalize(position - drag_current)
        arrow_end := drag_current + direction * 20
        rl.DrawLineEx(drag_current, arrow_end, 2, rl.RED)
        
        drag_distance := m.length(drag_current - position)
        fling_strength := m.clamp(drag_distance * FLING_FACTOR, MIN_VELOCITY, MAX_VELOCITY)
        strength_ratio := (fling_strength - MIN_VELOCITY) / (MAX_VELOCITY - MIN_VELOCITY)
        rl.DrawCircleV(position, 5 + strength_ratio * 15, rl.YELLOW)
    }
}

when ODIN_OS == .Windows {
    foreign import kernel32 "system:kernel32.lib"
    
    @(default_calling_convention="stdcall")
    foreign kernel32 {
        AllocConsole :: proc() -> i32 ---
        FreeConsole :: proc() -> i32 ---
    }
}