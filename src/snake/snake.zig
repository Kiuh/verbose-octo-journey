const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Vec2 = @import("../vec2.zig").Vec2;
const utils = @import("../utils.zig");
const Direction = utils.Direction;
const GameConfig = @import("../game_config.zig").GameConfig;

const Segment = @import("segment.zig").Segment;

pub const Snake = struct {
    segments: ArrayList(Segment) = undefined,

    last_movement_dir: Direction = .down,
    input_direction: Direction = .none,

    // I'd leave this a reference if we want to read and update it on-the-fly in the future
    gcfg: GameConfig = undefined,

    pub fn init(gcfg: GameConfig) Snake {
        return .{
            .segments = ArrayList(Segment).empty,
            .gcfg = gcfg,
        };
    }

    pub fn deinit(self: *Snake, allocator: Allocator) void {
        self.segments.deinit(allocator);
    }

    pub fn get_head(self: *Snake) Segment {
        return self.segments.items[0];
    }

    pub fn restart(self: *Snake, allocator: Allocator) !void {
        self.segments.clearAndFree(allocator);
        self.last_movement_dir = .down;
        self.input_direction = .none;

        for (0..self.gcfg.init_snake_length) |i| {
            const seg = Segment{
                .pos = .{
                    .x = self.gcfg.init_snake_pos.x,
                    .y = self.gcfg.init_snake_pos.y - 1 * @as(i32, @intCast(i)),
                },
            };
            try self.segments.append(allocator, seg);
        }
    }

    pub fn grow(self: *Snake, allocator: Allocator, seg: Segment) !void {
        try self.segments.append(allocator, seg);
    }

    pub fn check_overlap(self: *Snake) bool {
        const head = self.segments.items[0];
        for (self.segments.items) |seg| {
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
                if (self.input_direction != .none) {
                    self.last_movement_dir = self.input_direction;
                }
                self.segments.items[i].pos = Vec2.add(segment.pos, utils.direction_to_vector(self.last_movement_dir));
                self.input_direction = .none;
                pos_to_set = prev_pos;
                continue;
            }
            self.segments.items[i].pos = pos_to_set;
            pos_to_set = prev_pos;
        }
    }
};
