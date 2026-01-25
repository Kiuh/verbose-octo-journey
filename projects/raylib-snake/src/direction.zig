const Vec2 = @import("vec2.zig").Vec2;

pub const Direction = enum {
    none,
    up,
    down,
    right,
    left,

    pub fn asVec2(self: Direction) Vec2 {
        return switch (self) {
            .up => .{ .x = 0, .y = -1 },
            .down => .{ .x = 0, .y = 1 },
            .right => .{ .x = 1, .y = 0 },
            .left => .{ .x = -1, .y = 0 },
            .none => Vec2.zero,
        };
    }

    pub fn getOpposite(self: Direction) Direction {
        return switch (self) {
            .up => .down,
            .down => .up,
            .right => .left,
            .left => .right,
            .none => .none,
        };
    }

    pub fn isOppositeTo(self: Direction, other: Direction) bool {
        return self.getOpposite() == other;
    }
};
