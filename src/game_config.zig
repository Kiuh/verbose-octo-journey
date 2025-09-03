const rl = @import("raylib");
const Color = rl.Color;

const Vec2 = @import("vec2.zig").Vec2;

pub const GameConfig = struct {
    // System constants
    title: [:0]const u8 = undefined,
    start_screen_size: Vec2 = undefined,
    target_fps: i32 = undefined,

    // Game constants
    init_snake_pos: Vec2 = undefined,
    init_snake_length: usize = undefined,

    init_world_size: Vec2 = undefined,

    reduce_size_factor: f32 = undefined,

    init_apple_count: usize = undefined,

    // Rendering
    line_thikness: f32 = undefined,

    background_color: Color = undefined,
    lines_color: Color = undefined,
    apple_color: Color = undefined,
    snake_color: Color = undefined,
};
