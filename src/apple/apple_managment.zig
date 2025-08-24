const std = @import("std");
const Apple = @import("apple.zig").Apple;
const Vec2 = @import("../vec2.zig").Vec2;
const Segment = @import("../snake/segment.zig").Segment;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const rand = std.crypto.random;

const COUNT_OF_APPLES = 12;

pub const AppleManagement = struct {
    list: ArrayList(Apple) = undefined,

    pub fn init(allocator: Allocator, segments: *const ArrayList(Segment), height: i32, width: i32) !AppleManagement {
        var applesManagement = AppleManagement{};
        applesManagement.list = ArrayList(Apple).init(allocator);
        for (0..COUNT_OF_APPLES) |_| {
            var apple: Apple = undefined;
            var isFounded = false;
            while (!isFounded) {
                apple = Apple{
                    .pos = Vec2{
                        .x = rand.intRangeAtMost(i32, 0, width - 1),
                        .y = rand.intRangeAtMost(i32, 0, height - 1),
                    },
                };
                for (segments.items) |item| {
                    if (!Vec2.isEqual(item.pos, apple.pos)) {
                        isFounded = true;
                    }
                }
                for (applesManagement.list.items) |item| {
                    if (!Vec2.isEqual(item.pos, apple.pos)) {
                        isFounded = true;
                    }
                }
            }
            try applesManagement.list.append(apple);
        }

        return applesManagement;
    }

    pub fn restart(self: *AppleManagement, segments: *const ArrayList(Segment), height: i32, width: i32) !void {
        self.list.clearAndFree();
        for (0..COUNT_OF_APPLES) |_| {
            var apple: Apple = undefined;
            var isFounded = false;
            while (!isFounded) {
                apple = Apple{
                    .pos = Vec2{
                        .x = rand.intRangeAtMost(i32, 0, width - 1),
                        .y = rand.intRangeAtMost(i32, 0, height - 1),
                    },
                };
                for (segments.items) |item| {
                    if (!Vec2.isEqual(item.pos, apple.pos)) {
                        isFounded = true;
                    }
                }
                for (self.list.items) |item| {
                    if (!Vec2.isEqual(item.pos, apple.pos)) {
                        isFounded = true;
                    }
                }
            }
            try self.list.append(apple);
        }
    }

    pub fn get_position(self: *AppleManagement, segments: *ArrayList(Segment), height: i32, width: i32) Vec2 {
        var isFinded = false;

        var candidate: Vec2 = Vec2{
            .x = rand.intRangeAtMost(i32, 0, width - 1),
            .y = rand.intRangeAtMost(i32, 0, height - 1),
        };

        while (!isFinded) {
            var isInApple = false;
            var isInSnake = false;

            for (self.list.items) |apple| {
                if (Vec2.isEqual(candidate, apple.pos)) {
                    isInApple = true;
                }
            }
            for (segments.items) |item| {
                if (Vec2.isEqual(candidate, item.pos)) {
                    isInSnake = true;
                }
            }
            if (!isInSnake and !isInApple) {
                isFinded = true;
            } else {
                if (candidate.x < width - 1) {
                    candidate = Vec2{
                        .x = candidate.x + 1,
                        .y = candidate.y,
                    };
                } else if (candidate.x == width - 1 and candidate.y <= height) {
                    candidate = Vec2{
                        .x = 0,
                        .y = candidate.y + 1,
                    };
                } else {
                    candidate = Vec2{
                        .x = 0,
                        .y = 0,
                    };
                }
            }
        }

        return candidate;
    }

    pub fn check_apples(self: *AppleManagement, segments: *ArrayList(Segment), height: i32, width: i32) bool {
        const head = segments.items[0];

        for (self.list.items, 0..) |apple, i| {
            if (Vec2.isEqual(apple.pos, head.pos)) {
                const newPos: Vec2 = self.get_position(segments, height, width);
                self.list.items[i].pos = newPos;

                return true;
            }
        }
        return false;
    }

    pub fn deinit(self: *AppleManagement) void {
        self.list.deinit();
    }
};
