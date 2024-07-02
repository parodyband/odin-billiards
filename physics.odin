package main
import m   "core:math/linalg"
import rl  "vendor:raylib"
import fmt "core:fmt"
import     "core:strconv"
import     "core:mem"

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

check_ball_polygon_collision :: proc(ball: ^Ball, collider: ^PolygonCollider) {
    if ball.velocity == {0, 0} do return
    using collider
    ball_radius := f32(BALL_SCALE / 2)
    vertex_count := len(collider.vertices)
    
    closest_point: rl.Vector2
    min_distance := max(f32)
    collision_normal: rl.Vector2
    
    for i := 0; i < vertex_count; i += 1 {
        a := collider.vertices[i]
        b := collider.vertices[(i + 1) % vertex_count]

        // Find the closest point on the line segment to the ball
        ap := ball.position - a
        ab := b - a
        t := clamp(m.dot(ap, ab) / m.dot(ab, ab), 0, 1)
        closest := a + ab * t

        // Calculate the distance and normal
        to_ball := ball.position - closest
        distance := m.length(to_ball)

        if distance < min_distance {
            min_distance = distance
            closest_point = closest
            collision_normal = m.normalize(to_ball)
        }

        // Debug visualization
        center_point := (a + b) / 2
        outward_normal := rl.Vector2{ab.y, -ab.x}
        outward_normal = m.normalize(outward_normal)
        if RENDER_DEBUG {
            rl.DrawLineEx(a, b, 2, rl.RED)
            rl.DrawLineEx(center_point, center_point + outward_normal * 20, 2, rl.GREEN)
        }
    }

    // Check if collision occurred
    if min_distance <= ball_radius {
        // Collision detected, update ball position and velocity
        ball.position = closest_point + collision_normal * ball_radius
        ball.velocity = m.reflect(ball.velocity, collision_normal) * RESTITUTION
    }
    if RENDER_DEBUG {
        // Debug visualization for closest point and normal
        rl.DrawCircleV(closest_point, 5, rl.BLUE)
        rl.DrawLineEx(closest_point, closest_point + collision_normal * 20, 2, rl.YELLOW)
    }
}

edge_circle_collision :: proc(circle_center, circle_previous_center, line_start, line_end: rl.Vector2) -> bool {
    line_dir := m.normalize(line_end - line_start)
    line_normal := rl.Vector2{line_dir.y, -line_dir.x} // Corrected normal calculation
    
    circle_to_line := circle_center - line_start
    circle_to_line_prev := circle_previous_center - line_start
    
    distance := m.dot(circle_to_line, line_normal)
    distance_prev := m.dot(circle_to_line_prev, line_normal)
    
    if distance * distance_prev < 0 {
        projection := line_start + line_dir * m.dot(circle_to_line, line_dir)
        if m.length(circle_center - projection) < BALL_SCALE / 2 {
            return true
        }
    }


    return false
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

invert_y :: proc(v: rl.Vector2) -> rl.Vector2 {
    return {v.x, f32(game.screen_height) - v.y}
}