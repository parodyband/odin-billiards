package main
import m "core:math/linalg"
import rl "vendor:raylib"

is_mouse_over_ball :: proc(ball: ^Ball) -> bool {
    mouse_pos := rl.GetMousePosition()
    ball_center := ball.position
    distance := m.length(mouse_pos - ball_center)
    return distance <= f32(BALL_SCALE) / 2
}

check_ball_wall_collision :: proc(ball: ^Ball) {
    x_offset := f32(180)
    y_offset := f32(180)
    ball_radius := f32(BALL_SCALE / 2)
    
    // Check Y-axis collision
    if ball.position.y - ball_radius < y_offset {
        ball.position.y = y_offset + ball_radius
        ball.velocity.y = abs(ball.velocity.y) * RESTITUTION
    } else if ball.position.y + ball_radius > f32(game.screen_height) - y_offset {
        ball.position.y = f32(game.screen_height) - y_offset - ball_radius
        ball.velocity.y = -abs(ball.velocity.y) * RESTITUTION
    }
    
    // Check X-axis collision
    if ball.position.x - ball_radius < x_offset {
        ball.position.x = x_offset + ball_radius
        ball.velocity.x = abs(ball.velocity.x) * RESTITUTION
    } else if ball.position.x + ball_radius > f32(game.screen_width) - x_offset {
        ball.position.x = f32(game.screen_width) - x_offset - ball_radius
        ball.velocity.x = -abs(ball.velocity.x) * RESTITUTION
    }
}

check_balls_collision :: proc() {
    for i := 0; i < BALL_COUNT; i += 1 {
        for j := i + 1; j < BALL_COUNT; j += 1 {
            resolve_collision(&game.balls[i], &game.balls[j])
        }
    }
}

resolve_collision :: proc(ball1, ball2: ^Ball) {
    delta := ball2.position - ball1.position
    distance := m.length(delta)
    if distance < BALL_SCALE {
        normal := m.normalize(delta)
        relative_velocity := ball2.velocity - ball1.velocity
        velocity_along_normal := m.dot(relative_velocity, normal)
        
        if velocity_along_normal > 0 do return
        
        impulse_scalar := -(1 + RESTITUTION) * velocity_along_normal / 2
        impulse := normal * impulse_scalar
        
        ball1.velocity -= impulse
        ball2.velocity += impulse
        
        // Separate balls to prevent overlapping
        overlap := BALL_SCALE - distance
        separation := normal * (overlap * 0.5)
        ball1.position -= separation
        ball2.position += separation
    }
}

check_minimum_velocity :: proc(ball: ^Ball) {
    if m.length(ball.velocity) < MIN_VELOCITY {
        ball.velocity = {0, 0}
    }
}