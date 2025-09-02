const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Vec2 = @import("../vec2.zig").Vec2;
const utils = @import("../utils.zig");
const Direction = utils.Direction;
const GameConfig = @import("../game_config.zig").GameConfig;

const Segment = @import("segment.zig").Segment;

pub const Snake = struct {
    segments: ArrayList(*Segment) = undefined,
    segments_allocator: Allocator = undefined,

    last_movement_dir: Direction = .down,
    input_direction: Direction = .none,

    gcfg: *const GameConfig = undefined,

    pub fn init(allocator: Allocator, gcfg: *const GameConfig) Snake {
        return .{
            .segments = ArrayList(*Segment).empty,
            .segments_allocator = allocator,
            .gcfg = gcfg,
        };
    }

    pub fn get_head(self: *const Snake) *Segment {
        return self.segments.items[0];
    }

    pub fn deinit(self: *Snake) void {
        self.segments.deinit(self.segments_allocator);
    }

    pub fn restart(self: *Snake) !void {
        self.segments.clearAndFree(self.segments_allocator);
        self.last_movement_dir = .down;
        self.input_direction = .none;
        std.log.debug("init snake legth: {}", .{self.gcfg.*.init_snake_length});
        for (0..self.gcfg.*.init_snake_length) |i| {
            var seg = Segment{};
            seg.pos = Vec2{
                .x = self.gcfg.init_snake_pos.x,
                .y = self.gcfg.init_snake_pos.y - 1 * @as(i32, @intCast(i)),
            };
            std.log.debug("len: {}, capacity: {}", .{ self.segments.items.len, self.segments.capacity });
            // this is where it messes up
            try self.segments.append(self.segments_allocator, &seg);
        }
    }

    pub fn grow(self: *Snake, new_segment: *Segment) !void {
        std.log.debug("len: {}, capacity: {}", .{ self.segments.items.len, self.segments.capacity });
        try self.segments.append(self.segments_allocator, new_segment);
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
