const Vec2 = @import("vec2.zig").Vec2;

pub const Direction = enum {
    none,
    up,
    down,
    right,
    left,
};

pub fn direction_to_vector(dir: Direction) Vec2 {
    switch (dir) {
        Direction.up => {
            return Vec2{ .x = 0, .y = -1 };
        },
        Direction.down => {
            return Vec2{ .x = 0, .y = 1 };
        },
        Direction.right => {
            return Vec2{ .x = 1, .y = 0 };
        },
        Direction.left => {
            return Vec2{ .x = -1, .y = 0 };
        },
        Direction.none => {
            return Vec2{ .x = 0, .y = 0 };
        },
    }
}
