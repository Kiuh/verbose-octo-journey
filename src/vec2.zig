const rl = @import("raylib");

pub const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn create(x: i32, y: i32) Vec2 {
        return .{
            .x = x,
            .y = y,
        };
    }

    pub fn isEqual(a: Vec2, b: Vec2) bool {
        return a.x == b.x and a.y == b.y;
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x + b.x,
            .y = a.y + b.y,
        };
    }

    pub fn min(self: *Vec2) i32 {
        if (self.x < self.y) {
            return self.x;
        } else {
            return self.y;
        }
    }

    pub fn rlVec2(self: *Vec2) rl.Vector2 {
        return .{
            .x = @as(f32, @floatFromInt(self.x)),
            .y = @as(f32, @floatFromInt(self.y)),
        };
    }

    pub fn to_rl_vec2(vec: Vec2) rl.Vector2 {
        return .{
            .x = @as(f32, @floatFromInt(vec.x)),
            .y = @as(f32, @floatFromInt(vec.y)),
        };
    }
};
