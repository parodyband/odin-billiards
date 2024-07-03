package main

import rl    "vendor:raylib"
import m     "core:math/linalg"
import       "core:math/rand"
import fmt   "core:fmt"
import time  "core:time"
import win32 "core:sys/windows"
import       "core:strconv"

// Constants
BALL_SCALE    :: 64
PHYSICS_FPS   :: 60
PHYSICS_DT    :: 1.0 / f32(PHYSICS_FPS)
MIN_VELOCITY  :: 5.0
MAX_VELOCITY  :: 4000.0
FRICTION      :: 0.99
BALL_COUNT    :: 16
RESTITUTION   :: 0.9999
FLING_FACTOR  :: 10.0   
RENDER_DEBUG  :: false
BALL_DIAMETER :: f32(BALL_SCALE) * 1.1
RACK_X_OFFSET :: 0.7      // Percentage of screen width
RACK_Y_OFFSET :: 0.5      // Percentage of screen height
CUE_BALL_X_OFFSET :: 0.25 // Percentage of screen width for cue ball

DIRECTION_UP     :: rl.Vector2{0, -1}
DIRECTION_DOWN   :: rl.Vector2{0, 1}
DIRECTION_LEFT   :: rl.Vector2{-1, 0}
DIRECTION_RIGHT  :: rl.Vector2{1, 0}
DIRECTION_UPLEFT :: rl.Vector2{-0.707, -0.707}
DIRECTION_UPRIGHT:: rl.Vector2{0.707, -0.707}
DIRECTION_DOWNLEFT :: rl.Vector2{-0.707, 0.707}
DIRECTION_DOWNRIGHT:: rl.Vector2{0.707, 0.707}

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
    drag_current                                        : rl.Vector2,
    rotation                                            : rl.Vector3,
    is_out_of_play                                      : bool,
    angular_velocity                                    : rl.Vector3,
    texture                                             : rl.Texture2D,
    can_fling                                           : bool,
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
    ball_shader        : rl.Shader,
    fullscreen_texture : rl.RenderTexture2D,
    real_screen_params : rl.Vector2,
    time               : f64,
    delta_time         : f32,
    balltextures       : [16]rl.Texture2D
}

PolygonCollider :: struct {
    vertices : [dynamic]rl.Vector2,
}

CircleCollider :: struct {
    position : rl.Vector2,
    radius   : f32,
}

BallAnimation :: struct {
    frames: [4][12]rl.Rectangle,
}


// Global state
game : GameState

colliders : [6]PolygonCollider
circle_colliders : [6]CircleCollider


main :: proc() {
    init_game()
    defer cleanup()

    for !rl.WindowShouldClose() {
        set_window_parameters(game.screen_width, game.screen_height, &game.real_screen_params)
        delta_time := rl.GetFrameTime()
        update_game(delta_time)
        draw_game(delta_time)
    }
}

init_game :: proc() {
    game.screen_width  = 1920
    game.screen_height = 1080
    monitor_id := i32(0)

    rl.InitWindow(game.screen_width, game.screen_height, "Billiards")
    rl.InitAudioDevice()
    rl.SetWindowIcon(load_image_from_embedded(TextureData.icon))
    rl.SetWindowMonitor(monitor_id)
    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.VSYNC_HINT})
    rl.HideCursor()
    refresh_rate := rl.GetMonitorRefreshRate(monitor_id)
    rl.SetTargetFPS(refresh_rate)

    game.real_screen_params = rl.Vector2{f32(game.screen_width), f32(game.screen_height)}
    game.fullscreen_texture = rl.LoadRenderTexture(game.screen_width, game.screen_height)
    game.sprite_atlas = load_texture_from_embedded(TextureData.sprite_sheet)
    game.ball_shader = load_shader_from_embedded(ShaderData.ball_shader_frag, ShaderData.ball_shader_vert)
    init_data()
}

init_data :: proc() {

    using game
    init_sounds()
    default_font = load_font_from_embedded(FontData.romulus)
    if default_font.texture.id == 0 {
        fmt.println("Failed to load embedded font")
    } else {
        fmt.println("Embedded font loaded successfully: baseSize=%d, glyphCount=%d\n", 
                default_font.baseSize, default_font.glyphCount)
    }

    // Compare with loading from file
    file_font := rl.LoadFont("resources/fonts/romulus.png")
    if file_font.texture.id == 0 {
        fmt.println("Failed to load font from file")
    } else {
        fmt.println("File font loaded successfully: baseSize=%d, glyphCount=%d\n", 
                file_font.baseSize, file_font.glyphCount)
    }
    // Table
    table = Table{
        atlasBounds     = {0, 0, 224, 128},
        collisionBounds = {23, 23, 178, 82},
        position        = {0, 0},
    }

    tableBounds := rl.Vector2{f32(screen_width), f32(screen_height)}
    table.position = {
        f32(screen_width) / 2 - tableBounds.x / 2,
        f32(screen_height) / 2 - tableBounds.y / 2,
    }
    width_factor  := f32(screen_width) / table.atlasBounds.width
    height_factor := f32(screen_height) / table.atlasBounds.height

    // Cursor
    cursor = Cursor{
        atlasBounds = {224, 64, 32, 32},
        position    = {0, 0},
    }

    game.balltextures[0] = load_texture_from_embedded(TextureData.ball_1)
    game.balltextures[1] = load_texture_from_embedded(TextureData.ball_2)
    game.balltextures[2] = load_texture_from_embedded(TextureData.ball_3)
    game.balltextures[3] = load_texture_from_embedded(TextureData.ball_4)
    game.balltextures[4] = load_texture_from_embedded(TextureData.ball_5)
    game.balltextures[5] = load_texture_from_embedded(TextureData.ball_6)
    game.balltextures[6] = load_texture_from_embedded(TextureData.ball_7)
    game.balltextures[7] = load_texture_from_embedded(TextureData.ball_8)
    game.balltextures[8] = load_texture_from_embedded(TextureData.ball_9)
    game.balltextures[9] = load_texture_from_embedded(TextureData.ball_10)
    game.balltextures[10] = load_texture_from_embedded(TextureData.ball_11)
    game.balltextures[11] = load_texture_from_embedded(TextureData.ball_12)
    game.balltextures[12] = load_texture_from_embedded(TextureData.ball_13)
    game.balltextures[13] = load_texture_from_embedded(TextureData.ball_14)
    game.balltextures[14] = load_texture_from_embedded(TextureData.ball_15)
    game.balltextures[15] = load_texture_from_embedded(TextureData.ball_16)

    // Balls
    for i := 0; i < BALL_COUNT; i += 1 {
        can_fling := BALL_COUNT-1 == i
        balls[i] = Ball{
            atlasBounds = {0, 0, 767, 767},
            position = {
                f32(screen_width) / 4 + f32(i) * f32(BALL_SCALE) * 1.1,
                f32(screen_height) / 2,
            },
            is_out_of_play = false,
            texture = game.balltextures[i],
            can_fling = can_fling,
        }
        balls[i].previousPosition = balls[i].position
    }
    rack_balls(&balls)

    colliders[0] = PolygonCollider{
        vertices = {
            {26, 16},
            {103, 16},
            {98, 22},
            {32, 22},
        }
    }
    colliders[1] = PolygonCollider{
        vertices = {
            {121, 16},
            {198, 16},
            {193, 22},
            {126, 22},
        }
    }
    colliders[2] = PolygonCollider{
        vertices = {
            {25, 112},
            {32, 106},
            {97, 106},
            {103, 112},
        }
    }
    colliders[3] = PolygonCollider{
        vertices = {
            {121, 112},
            {126, 106},
            {193, 106},
            {198, 112},
        }
    }
    colliders[4] = PolygonCollider{
        vertices = {
            {16, 25},
            {22, 32},
            {22, 97},
            {16, 103},
        }
    }
    colliders[5] = PolygonCollider{
        vertices = {
            {202, 31},
            {208, 25},
            {208, 103},
            {202, 97},
        }
    }
    for collider in colliders {
        for i := 0; i < len(collider.vertices); i += 1 {
            collider.vertices[i] = collider.vertices[i] * rl.Vector2{width_factor, height_factor}
        }
    }

    circle_colliders[0] = CircleCollider{
        position = {16, 16},
        radius = 8,
    }
    circle_colliders[1] = CircleCollider{
        position = {208, 16},
        radius = 8,
    }
    circle_colliders[2] = CircleCollider{
        position = {16, 112},
        radius = 8,
    }
    circle_colliders[3] = CircleCollider{
        position = {208, 112},
        radius = 8,
    }
    circle_colliders[4] = CircleCollider{
        position = {112, 16},
        radius = 8,
    }
    circle_colliders[5] = CircleCollider{
        position = {112, 112},
        radius = 8,
    }

    for i := 0; i < len(circle_colliders); i += 1 {
        circle_colliders[i].position = circle_colliders[i].position * rl.Vector2{width_factor, height_factor}
        circle_colliders[i].radius *= width_factor
    }
}

cleanup :: proc() {
    rl.UnloadRenderTexture(game.fullscreen_texture)
    rl.UnloadTexture(game.sprite_atlas)
    for i := 0; i < BALL_COUNT; i += 1 {
        rl.UnloadTexture(game.balls[i].texture)
    }
    rl.UnloadShader(game.ball_shader)
    UnloadSoundsFromPool(rack_sound_pool)
    UnloadSoundsFromPool(strike_sound_pool)
    UnloadSoundsFromPool(hit_sound_pool)
    UnloadSoundsFromPool(side_hit_sound_pool)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}

update_game :: proc(delta_time: f32) {
    update_cursor()
    mouse_over_any_ball := false

    if rl.IsKeyPressed(rl.KeyboardKey.R) {
        rack_balls(&game.balls)
    }
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
        if game.balls[i].is_out_of_play {
            continue
        }

        for j := i + 1; j < BALL_COUNT; j += 1 {
            resolve_collision(&game.balls[i], &game.balls[j])
        }
        update_ball(&game.balls[i], delta_time)
        //wrap if offscreen
        if game.balls[i].position.x < 0 {
            game.balls[i].position.x = f32(game.screen_width)
        } else if game.balls[i].position.x > f32(game.screen_width) {
            game.balls[i].position.x = 0
        }
        if game.balls[i].position.y < 0 {
            game.balls[i].position.y = f32(game.screen_height)
        } else if game.balls[i].position.y > f32(game.screen_height) {
            game.balls[i].position.y = 0
        }
    }
}

update_ball :: proc(ball: ^Ball, delta_time: f32) {
    ball.previousPosition = ball.position
    ball.position += ball.velocity * delta_time
    ball.velocity *= FRICTION
    check_ball_polygon_collision(ball, colliders[:])

    // eventually make this nicer, animation maybe
    should_disable := check_ball_circle_trigger(ball, circle_colliders[:])
    if should_disable {
        if ball.can_fling {
            ball.position = rl.Vector2{
                f32(game.screen_width) * CUE_BALL_X_OFFSET,
                f32(game.screen_height) * RACK_Y_OFFSET,
            }
            ball.velocity = {0, 0}
            ball.angular_velocity = {0, 0, 0}
        } else {
            PlayRandomAudioFromPool(&pocket_sound_pool)
            ball.is_out_of_play = true
        }
       
    }
    check_minimum_velocity(ball)
}

rack_balls :: proc(balls: ^[BALL_COUNT]Ball) {
    triangle_positions := [15]rl.Vector2{
        rl.Vector2{0, 0},
        rl.Vector2{0.866, -0.5},    // (sqrt(3)/2, -1)
        rl.Vector2{0.866, 0.5},
        rl.Vector2{1.732, -1},      // (sqrt(3), -2)
        rl.Vector2{1.732, 0},
        rl.Vector2{1.732, 1},
        rl.Vector2{2.598, -1.5},    // (3*sqrt(3)/2, -3)
        rl.Vector2{2.598, -0.5},
        rl.Vector2{2.598, 0.5},
        rl.Vector2{2.598, 1.5},
        rl.Vector2{3.464, -2},      // (2*sqrt(3), -4)
        rl.Vector2{3.464, -1},
        rl.Vector2{3.464, 0},
        rl.Vector2{3.464, 1},
        rl.Vector2{3.464, 2},
    }

    start_x := f32(game.screen_width) * RACK_X_OFFSET
    start_y := f32(game.screen_height) * RACK_Y_OFFSET
    ball_radius := BALL_DIAMETER * 0.9

    for i := 0; i < len(triangle_positions); i += 1 {
        balls[i].position = rl.Vector2{
            start_x + triangle_positions[i].x * ball_radius,
            start_y + triangle_positions[i].y * ball_radius,
        }
        balls[i].velocity = {0, 0}
        balls[i].is_out_of_play = false
        balls[i].previousPosition = balls[i].position
        balls[i].angular_velocity = {0, 0, 0}
        balls[i].rotation = {0, 0, 0}
    }

    // Position the cue ball
    cue_ball := &balls[BALL_COUNT - 1]
    cue_ball.position = rl.Vector2{
        f32(game.screen_width) * CUE_BALL_X_OFFSET,
        f32(game.screen_height) * RACK_Y_OFFSET,
    }
    cue_ball.velocity = {0, 0}
    cue_ball.is_out_of_play = false
    cue_ball.previousPosition = cue_ball.position
    cue_ball.angular_velocity = {0, 0, 0}
    PlayRandomAudioFromPool(&rack_sound_pool)
}

start_drag :: proc(ball: ^Ball) {
    ball.is_dragging = true
    ball.drag_current = rl.GetMousePosition()
}

end_drag :: proc(ball: ^Ball) {
    if ball.is_dragging && ball.can_fling{
        ball.is_dragging = false
        fling_vector := ball.position - ball.drag_current
        drag_distance := m.length(fling_vector)
        
        if drag_distance > 1 {
            fling_strength := clamp(drag_distance * FLING_FACTOR, MIN_VELOCITY, MAX_VELOCITY)
            fling_velocity := m.normalize(fling_vector) * fling_strength
            ball.velocity = fling_velocity
            PlayRandomAudioFromPool(&strike_sound_pool)
        }
    }
}

update_cursor :: proc() {
    game.cursor.position = rl.GetMousePosition()
}

draw_game :: proc(delta_time: f32) {
    rl.BeginTextureMode(game.fullscreen_texture)
    rl.ClearBackground(rl.BLACK)
    draw_table()

    if RENDER_DEBUG {
        draw_debug_colliders()
    }

    draw_balls()
    update_physics(delta_time)

    rl.DrawFPS(10, 10)
    //draw text to say press r to re rack
    rl.DrawTextEx(default_font,"Press R to re-rack", rl.Vector2{300,60}, 30, 2, rl.WHITE)
    rl.EndTextureMode()

    // Draw fullscreen texture
    {
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
}

draw_debug_colliders :: proc()
{
    for collider in circle_colliders {
        rl.DrawCircleLinesV(collider.position, collider.radius, rl.RED)
    }
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
        if game.balls[i].is_out_of_play {
            continue
        }
        draw_ball(&game.balls[i])
    }
}

draw_ball :: proc(using ball: ^Ball) {
    new_ball_scale := f32(BALL_SCALE * 1.5)
    dest_rect := rl.Rectangle{position.x - new_ball_scale/2, position.y - new_ball_scale/2, new_ball_scale, new_ball_scale}

    // Update rotation based on velocity
    speed := m.length(velocity)
    rotation_factor : f32 = 0.0001 // Adjust this to control rotation speed
    friction : f32 = 0.98 // Friction factor for rotation

    // Calculate rotation based on movement
    movement := position - previousPosition
    rotation_x := -movement.y * rotation_factor // Rotate around x-axis based on vertical movement
    rotation_y := movement.x * rotation_factor  // Rotate around y-axis based on horizontal movement
    
    // Update angular velocity
    angular_velocity.x -= rotation_x
    angular_velocity.y -= rotation_y
    angular_velocity.z -= speed * rotation_factor * 0.04 // Small z-rotation for rolling effect

    // Apply friction to angular velocity
    angular_velocity *= friction

    // Update rotation
    rotation += angular_velocity

    // Stop rotation when it's very slow
    min_angular_velocity : f32 = 0.001
    if m.length(angular_velocity) < min_angular_velocity {
        angular_velocity = {0, 0, 0}
    }

    ball_color := rl.WHITE
    if is_dragging && can_fling{
        ball_color = rl.GREEN
    } else if is_mouse_over_ball(ball) && can_fling{
        ball_color = rl.RED
    }
    
    rl.BeginShaderMode(game.ball_shader);

    // Pass rotation to shader
    rotation_loc := rl.GetShaderLocation(game.ball_shader, "iRotation")
    rl.SetShaderValue(game.ball_shader, rotation_loc, &rotation, rl.ShaderUniformDataType.VEC3)
    
    rl.DrawTexturePro(
        ball.texture,
        rl.Rectangle{0, 0, 64, 64},
        dest_rect,
        {0,0},
        0,
        ball_color
    )
    rl.EndShaderMode();
    if is_dragging && can_fling{
        //draw line to show fling strength
        rl.DrawLineEx(position, drag_current, 2, rl.BLUE)
        
        drag_distance := m.length(drag_current - position)
        fling_strength := m.clamp(drag_distance * FLING_FACTOR, MIN_VELOCITY, MAX_VELOCITY)
        strength_ratio := (fling_strength - MIN_VELOCITY) / (MAX_VELOCITY - MIN_VELOCITY)
        direciton_vector := m.normalize(drag_current - position)

        rl.DrawLineEx(position, position - direciton_vector * 500 * strength_ratio, 2, rl.RED)
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