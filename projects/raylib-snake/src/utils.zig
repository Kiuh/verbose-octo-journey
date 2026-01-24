const Vec2 = @import("vec2.zig").Vec2;

pub const Direction = enum {
    none,
    up,
    down,
    right,
    left,
};

pub fn directionToVector(dir: Direction) Vec2 {
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

pub fn getOppositeDirection(dir: Direction) Direction {
    switch (dir) {
        Direction.up => {
            return .down;
        },
        Direction.down => {
            return .up;
        },
        Direction.right => {
            return .left;
        },
        Direction.left => {
            return .right;
        },
        Direction.none => {
            return .none;
        },
    }
}
