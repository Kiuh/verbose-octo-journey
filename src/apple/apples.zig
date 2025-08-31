const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Vec2 = @import("../vec2.zig").Vec2;
const World = @import("../world.zig").World;
const GameConfig = @import("../game_config.zig").GameConfig;

const Apple = @import("apple.zig").Apple;
const Snake = @import("../snake/snake.zig").Snake;

pub const Apples = struct {
    rand: std.Random = undefined,

    list: ArrayList(Apple) = undefined,
    list_allocator: Allocator = undefined,

    snake: *const Snake = undefined,
    world: *const World = undefined,

    gcfg: *const GameConfig = undefined,

    pub fn init(
        allocator: Allocator,
        snake: *const Snake,
        world: *const World,
        gcfg: *const GameConfig,
    ) Apples {
        return .{
            .list = ArrayList(Apple).empty,
            .list_allocator = allocator,

            .snake = snake,
            .world = world,
            .gcfg = gcfg,

            .rand = std.crypto.random,
        };
    }

    pub fn restart(self: *Apples) !void {
        self.list.clearAndFree(self.list_allocator);

        for (0..self.gcfg.init_apple_count) |_| {
            var apple = Apple{};
            var isFounded = false;
            while (!isFounded) {
                apple.pos = Vec2{
                    .x = self.rand.intRangeAtMost(i32, 0, self.world.width - 1),
                    .y = self.rand.intRangeAtMost(i32, 0, self.world.height - 1),
                };
                for (self.snake.segments.items) |item| {
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
            try self.list.append(self.list_allocator, apple);
        }
    }

    pub fn get_position(self: *Apples) Vec2 {
        var isFinded = false;

        var candidate: Vec2 = Vec2{
            .x = self.rand.intRangeAtMost(i32, 0, self.world.width - 1),
            .y = self.rand.intRangeAtMost(i32, 0, self.world.height - 1),
        };

        while (!isFinded) {
            var isInApple = false;
            var isInSnake = false;

            for (self.list.items) |apple| {
                if (Vec2.isEqual(candidate, apple.pos)) {
                    isInApple = true;
                }
            }
            for (self.snake.segments.items) |item| {
                if (Vec2.isEqual(candidate, item.pos)) {
                    isInSnake = true;
                }
            }

            if (!isInSnake and !isInApple) {
                isFinded = true;
            } else {
                if (candidate.x < self.world.width - 1) {
                    candidate = Vec2{
                        .x = candidate.x + 1,
                        .y = candidate.y,
                    };
                } else if (candidate.x == self.world.width - 1 and candidate.y <= self.world.height) {
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

    pub fn check_apples(self: *Apples) bool {
        const head = self.snake.get_head();

        for (self.list.items, 0..) |apple, i| {
            if (Vec2.isEqual(apple.pos, head.pos)) {
                const newPos: Vec2 = self.get_position();
                self.list.items[i].pos = newPos;

                return true;
            }
        }
        return false;
    }

    pub fn deinit(self: *Apples) void {
        self.list.deinit(self.list_allocator);
    }
};
