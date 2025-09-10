const Vec2 = @import("vec2.zig").Vec2;

pub const Direction = enum {
    none,
    upward,
    downward,
    right,
    left,
};

pub fn directionToVector(dir: Direction) Vec2 {
    switch (dir) {
        Direction.upward => {
            return Vec2{ .x = 0, .y = -1 };
        },
        Direction.downward => {
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
