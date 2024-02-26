package rune

import glm "core:math/linalg/glsl"
import "core:math"

TAO :f64: (2 * math.PI)
PI_2 :f64: (math.PI * 2)

Camera :: struct{
    fov: f32,
    aspect: f32,

    yaw: f64,
    pitch: f64,


    position: glm.vec3,
    direction: glm.vec3,
    up: glm.vec3,
}

// --------------------------------------------------------------

// Create a camera
CreateCamera :: proc(camera_position: glm.vec3, camera_direction: glm.vec3, window_width, window_height: f32) -> Camera {
    return Camera {
        fov = 45,
        aspect = window_width / window_height,

        yaw = -90.0,
        pitch = 0.0,

        position = camera_position,
        direction = camera_direction,
        up = {0.0, 1.0, 0.0},
    }
}

// --------------------------------------------------------------

UpdateFirstPersonCamera :: proc(camera: ^Camera, sensitivity, offset_x, offset_y: f64, ) {

    // Calculate the pitch and yaw from mouse offset from last frame
	camera.yaw += offset_x * sensitivity
	camera.pitch += offset_y * sensitivity

    // Set limits for both the pitch and yaw
    camera.pitch = math.clamp(camera.pitch, -((math.PI * 0.9) / 2 ), (math.PI * 0.9) / 2)
    camera.yaw = (camera.yaw < 0 ? PI_2 : 0.0) + math.remainder_f64(camera.yaw, TAO)
    
    // Calculate the directional vector from the pitch and yaw
    direction := glm.vec3{
        f32(math.cos(camera.pitch) * math.sin(camera.yaw)),
        f32(math.sin(camera.pitch)),
        f32(math.cos(camera.pitch) * math.cos(camera.yaw)),
    }

    camera.direction = glm.normalize(direction)
}

// --------------------------------------------------------------


RelTranslateCameraX :: proc(camera: ^Camera, offset: f32) {
    camera.position += glm.normalize(glm.cross(camera.direction, camera.up)) * offset
}
RelTranslateCameraY :: proc(camera: ^Camera, offset: f32) {
    camera.position += camera.up * offset
}
RelTranslateCameraZ :: proc(camera: ^Camera, offset: f32) {
    camera.position.xz += { f32(math.sin(camera.yaw)), f32(math.cos(camera.yaw)) } * offset
}

GetViewMatrix :: proc(camera: ^Camera) -> matrix[4,4]f32 {
    return glm.mat4LookAt(camera.position, camera.position + camera.direction, camera.up)
    //return camera.view
}
GetProjectionMatrix :: proc(camera: ^Camera) -> matrix[4,4]f32 {
    return glm.mat4Perspective(camera.fov, camera.aspect, 0.1, 100.0)
    //return camera.projection
}
