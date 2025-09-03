const Vec2 = @import("vec2.zig").Vec2;

pub const World = struct {
    width: i32 = undefined,
    height: i32 = undefined,

    pub fn init(size: Vec2) World {
        return .{
            .width = size.x,
            .height = size.y,
        };
    }
};
