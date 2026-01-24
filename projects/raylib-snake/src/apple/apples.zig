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

    snake: *Snake = undefined,
    world: *World = undefined,

    gcfg: GameConfig = undefined,

    pub fn init(snake: *Snake, world: *World, gcfg: GameConfig) Apples {
        return .{
            .rand = std.crypto.random,
            .list = ArrayList(Apple).empty,

            .snake = snake,
            .world = world,

            .gcfg = gcfg,
        };
    }

    pub fn deinit(self: *Apples, allocator: Allocator) void {
        self.list.deinit(allocator);
    }

    pub fn restart(self: *Apples, allocator: Allocator) !void {
        self.list.clearAndFree(allocator);

        for (0..self.gcfg.init_apple_count) |_| {
            const pos = self.getPosition();
            try self.list.append(allocator, .{ .pos = pos });
        }
    }

    pub fn getPosition(self: *Apples) Vec2 {
        var candidate: Vec2 = Vec2{
            .x = self.rand.intRangeAtMost(i32, 0, self.world.width - 1),
            .y = self.rand.intRangeAtMost(i32, 0, self.world.height - 1),
        };

        while (true) {
            var overlap_found = false;

            for (self.list.items) |apple| {
                if (Vec2.isEqual(candidate, apple.pos)) {
                    overlap_found = true;
                }
            }
            for (self.snake.segments.items) |item| {
                if (Vec2.isEqual(candidate, item.pos)) {
                    overlap_found = true;
                }
            }

            if (!overlap_found) {
                return candidate;
            }

            if (candidate.x < self.world.width - 1) {
                candidate = Vec2{ .x = candidate.x + 1, .y = candidate.y };
            } else if (candidate.y < self.world.height - 1) {
                candidate = Vec2{ .x = 0, .y = candidate.y + 1 };
            } else {
                candidate = Vec2{ .x = 0, .y = 0 };
            }
        }

        return candidate;
    }

    pub fn checkApples(self: *Apples) i32 {
        const head = self.snake.getHead();

        for (self.list.items, 0..) |apple, i| {
            if (Vec2.isEqual(apple.pos, head.pos)) {
                // this line was a very bad implicit side effect so I've moved it out
                return @as(i32, @intCast(i));
            }
        }
        return -1;
    }
};
