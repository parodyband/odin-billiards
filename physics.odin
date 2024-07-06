package main

import m   "core:math/linalg"
import rl  "vendor:raylib"
import fmt "core:fmt"
import     "core:strconv"
import     "core:mem"

is_mouse_over_ball :: #force_inline proc(ball: ^Ball) -> bool {
    return m.length(rl.GetMousePosition() - ball.position) <= f32(BALL_SCALE) / 2
}

check_ball_wall_collision :: proc(ball: ^Ball) {
    x_offset, y_offset := f32(180), f32(180)
    ball_radius := f32(BALL_SCALE / 2)
    
    // Check Y-axis collision
    if ball.position.y < y_offset + ball_radius {
        ball.position.y = y_offset + ball_radius
        ball.velocity.y = abs(ball.velocity.y) * RESTITUTION
    } else if ball.position.y > f32(game.screen_height) - y_offset - ball_radius {
        ball.position.y = f32(game.screen_height) - y_offset - ball_radius
        ball.velocity.y = -abs(ball.velocity.y) * RESTITUTION
    }
    
    // Check X-axis collision
    if ball.position.x < x_offset + ball_radius {
        ball.position.x = x_offset + ball_radius
        ball.velocity.x = abs(ball.velocity.x) * RESTITUTION
    } else if ball.position.x > f32(game.screen_width) - x_offset - ball_radius {
        ball.position.x = f32(game.screen_width) - x_offset - ball_radius
        ball.velocity.x = -abs(ball.velocity.x) * RESTITUTION
    }
}

check_ball_polygon_collision :: proc(ball: ^Ball, colliders: []PolygonCollider) {
    if ball.velocity == {0, 0} do return

    ball_radius := f32(BALL_SCALE / 2)
    
    for collider in colliders {
        closest_point, min_distance, collision_normal := find_closest_point_on_polygon(ball.position, collider)

        if min_distance <= ball_radius {
            ball.position = closest_point + collision_normal * ball_radius
            ball.velocity = m.reflect(ball.velocity, collision_normal) * RESTITUTION
            PlayRandomAudioFromPool(&side_hit_sound_pool)
        }

        if RENDER_DEBUG do render_debug_info(collider, closest_point, collision_normal)
    }
}

find_closest_point_on_polygon :: proc(ball_position: rl.Vector2, collider: PolygonCollider) -> (rl.Vector2, f32, rl.Vector2) {
    closest_point: rl.Vector2
    min_distance := max(f32)
    collision_normal: rl.Vector2
    
    for i := 0; i < len(collider.vertices); i += 1 {
        a := collider.vertices[i]
        b := collider.vertices[(i + 1) % len(collider.vertices)]
        ap := ball_position - a
        ab := b - a
        t := clamp(m.dot(ap, ab) / m.dot(ab, ab), 0, 1)
        closest := a + ab * t
        to_ball := ball_position - closest
        distance := m.length(to_ball)

        if distance < min_distance {
            min_distance = distance
            closest_point = closest
            collision_normal = m.normalize(to_ball)
        }
    }
    
    return closest_point, min_distance, collision_normal
}

render_debug_info :: proc(collider: PolygonCollider, closest_point: rl.Vector2, collision_normal: rl.Vector2) {
    for i := 0; i < len(collider.vertices); i += 1 {
        a := collider.vertices[i]
        b := collider.vertices[(i + 1) % len(collider.vertices)]
        center_point := (a + b) / 2
        outward_normal := m.normalize(rl.Vector2{b.y - a.y, a.x - b.x})
        rl.DrawLineEx(center_point, center_point + outward_normal * 20, 2, rl.GREEN)
        rl.DrawLineEx(a, b, 2, rl.RED)
    }
    rl.DrawCircleV(closest_point, 5, rl.BLUE)
    rl.DrawLineEx(closest_point, closest_point + collision_normal * 20, 2, rl.YELLOW)
}

check_ball_circle_trigger :: proc(ball: ^Ball, colliders: []CircleCollider) -> bool {
    for collider in colliders {
        if m.length(ball.position - collider.position) < collider.radius {
            return true
        }
    }
    return false
}

edge_circle_collision :: proc(circle_center, circle_previous_center, line_start, line_end: rl.Vector2) -> bool {
    line_dir := m.normalize(line_end - line_start)
    line_normal := rl.Vector2{line_dir.y, -line_dir.x}
    
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

resolve_collision :: proc(ball1, ball2: ^Ball) {
    if ball1.is_out_of_play || ball2.is_out_of_play do return

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

        if m.length(impulse) > 15 do PlayRandomAudioFromPool(&hit_sound_pool)
        
        // Separate balls to prevent overlapping
        separation := normal * ((BALL_SCALE - distance) * 0.5)
        ball1.position -= separation
        ball2.position += separation
    }
}

check_minimum_velocity :: #force_inline proc(ball: ^Ball) {
    if m.length(ball.velocity) < MIN_VELOCITY {
        ball.velocity = {0, 0}
    }
}

invert_y :: #force_inline proc(v: rl.Vector2) -> rl.Vector2 {
    return {v.x, f32(game.screen_height) - v.y}
}