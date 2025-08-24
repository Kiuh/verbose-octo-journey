const std = @import("std");
const utils = @import("../utils.zig");
const Direction = utils.Direction;
const Segment = @import("segment.zig").Segment;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vec2 = @import("../vec2.zig").Vec2;

const START_SNAKE_LENGTH = 3;
const SNAKE_INIT_POS = Vec2{ .x = 0, .y = 0 };

pub const Snake = struct {
    segments: ArrayList(Segment) = undefined,
    length: usize = 0,
    last_movement_dir: Direction = Direction.down,
    input_direction: Direction = Direction.none,

    pub fn init(allocator: Allocator, pos: Vec2) !Snake {
        var snake = Snake{};
        snake.segments = ArrayList(Segment).init(allocator);
        snake.length = 3;
        for (0..snake.length) |idx| {
            const seg = Segment{
                .pos = Vec2{
                    .x = pos.x,
                    .y = pos.y - 1 * @as(i32, @intCast(idx)),
                },
            };
            try snake.segments.append(seg);
        }

        return snake;
    }

    pub fn deinit(self: *Snake) void {
        self.segments.deinit();
    }

    pub fn restart(self: *Snake, pos: Vec2) !void {
        self.segments.clearAndFree();
        self.length = 3;
        self.last_movement_dir = Direction.down;
        self.input_direction = Direction.none;

        for (0..self.length) |idx| {
            const seg = Segment{
                .pos = Vec2{
                    .x = pos.x,
                    .y = pos.y - 1 * @as(i32, @intCast(idx)),
                },
            };
            try self.segments.append(seg);
        }
    }

    pub fn grow(self: *Snake, new_segment: Segment) !void {
        try self.segments.append(Segment{ .pos = new_segment.pos });
        self.length += 1;
    }

    pub fn check_overlap(self: *Snake) bool {
        const head = self.segments.items[0];
        for (self.segments, 0..) |seg, idx| {
            _ = idx;
            if (Vec2.isEqual(seg.pos, head.pos)) {
                return true;
            }
        }
        return false;
    }

    pub fn move(self: *Snake) void {
        var prev_pos = Vec2{};
        var pos_to_set = Vec2{};
        for (self.segments.items, 0..) |segment, i| {
            // head
            prev_pos = self.segments.items[i].pos;
            if (i == 0) {
                if (self.input_direction != Direction.none) {
                    self.last_movement_dir = self.input_direction;
                }
                self.segments.items[i].pos = Vec2.add(segment.pos, utils.direction_to_vector(self.last_movement_dir));
                self.input_direction = Direction.none;
                pos_to_set = prev_pos;
                continue;
            }
            self.segments.items[i].pos = pos_to_set;
            pos_to_set = prev_pos;
        }
    }
};
