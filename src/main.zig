const std = @import("std");
const rl = @import("raylib");

const utils = @import("utils.zig");
const Vec2 = @import("vec2.zig").Vec2;

const AppleManagement = @import("apple/apple_managment.zig").AppleManagement;
const Segment = @import("snake/segment.zig").Segment;
const Snake = @import("snake/snake.zig").Snake;

const rand = std.crypto.random;
const Direction = utils.Direction;
const Color = rl.Color;

// System constants
const TITLE = "Collaboration zig's snake game";
var SCREEN_SIZE: Vec2 = .{ .x = 800, .y = 400 };

// Game constants
const SNAKE_INIT_POS = Vec2{ .x = 0, .y = 3 };

const WORLD_INIT_HEIGHT = 10;
const WORLD_INIT_WIDTH = 20;

const BACKGROUND_COLOR = Color.white;

const LINES_COLOR = Color.black;
const LINES_THIKNESS: f32 = 2.0;

const APPLE_COLOR = Color.red;

const BODY_FACTOR = 0.8;
const SNAKE_COLOR = Color.green;

// Default aliases

const Allocator = std.mem.Allocator;

const World = struct {
    width: i32 = 0,
    height: i32 = 0,

    pub fn init() World {
        return .{
            .width = WORLD_INIT_WIDTH,
            .height = WORLD_INIT_HEIGHT,
        };
    }
};

// Game variables
const Game = struct {
    world: World = undefined,
    snake: Snake = undefined,
    apple_manager: AppleManagement = undefined,

    block_size: rl.Vector2 = undefined,

    last_frame_time: i64 = 0,

    timer: i64 = 0,

    pub fn init(allocator: Allocator) !Game {
        const world = World.init();
        const snake = try Snake.init(allocator, SNAKE_INIT_POS);
        const apple_manager = try AppleManagement.init(allocator, &snake.segments, world.height, world.height);

        return .{
            .world = world,
            .snake = snake,
            .apple_manager = apple_manager,
            .block_size = rl.Vector2{ .x = 0, .y = 0 },
            .last_frame_time = std.time.milliTimestamp(),
        };
    }

    pub fn deinit(self: *Game) void {
        self.snake.deinit();
        self.apple_manager.deinit();
        self.last_frame_time = std.time.milliTimestamp();
    }

    pub fn restart(self: *Game) !void {
        try self.apple_manager.restart(&self.snake.segments, self.world.height, self.world.width);
        try self.snake.restart(SNAKE_INIT_POS);
    }

    pub fn hanle_input(self: *Game) void {
        if (rl.isKeyPressed(rl.KeyboardKey.right)) {
            self.snake.input_direction = Direction.right;
        } else if (rl.isKeyPressed(rl.KeyboardKey.left)) {
            self.snake.input_direction = Direction.left;
        } else if (rl.isKeyPressed(rl.KeyboardKey.up)) {
            self.snake.input_direction = Direction.up;
        } else if (rl.isKeyPressed(rl.KeyboardKey.down)) {
            self.snake.input_direction = Direction.down;
        }
    }

    pub fn check_snake(snake: *Snake, width: i32, height: i32) bool {
        const head = snake.segments.items[0];
        if (head.pos.x >= width or head.pos.x < 0 or head.pos.y >= height or head.pos.y < 0) {
            return true;
        }

        for (snake.segments.items, 0..) |item, index| {
            if (index != 0 and Vec2.isEqual(item.pos, head.pos)) {
                return true;
            }
        }

        return false;
    }

    pub fn update(self: *Game) !void {
        const delta_time: i64 = std.time.milliTimestamp() - self.last_frame_time;
        self.timer += delta_time;

        const tick_time = std.time.ms_per_s * 0.5;
        if (self.timer >= tick_time) {
            const last_segment: Segment = self.snake.segments.items[self.snake.segments.items.len - 1];
            self.snake.move();
            const need_restart = Game.check_snake(&self.snake, self.world.width, self.world.height);
            if (need_restart) {
                try self.restart();
                return;
            }

            const apple_found = self.apple_manager.check_apples(&self.snake.segments, self.world.height, self.world.width);
            if (apple_found) {
                try self.snake.grow(last_segment);
            }
            self.timer = 0;
        }

        self.last_frame_time = std.time.milliTimestamp();
    }

    fn get_grid_pos_offset(self: *Game, pos: Vec2) rl.Vector2 {
        return rl.Vector2{
            .x = self.block_size.x / 2.0 + utils.to_float(pos.x) * self.block_size.x,
            .y = self.block_size.y / 2.0 + utils.to_float(pos.y) * self.block_size.y,
        };
    }

    fn get_grid_pos(self: *Game, pos: Vec2) rl.Vector2 {
        return rl.Vector2{
            .x = utils.to_float(pos.x) * self.block_size.x,
            .y = utils.to_float(pos.y) * self.block_size.y,
        };
    }

    pub fn draw_grid(self: *Game) void {
        var i: i32 = 0;
        while (i <= self.world.width) : (i += 1) {
            const pos_x = utils.to_float(i) * self.block_size.x;
            const start_pos = rl.Vector2{ .x = pos_x, .y = 0 };
            const end_pos = rl.Vector2{ .x = pos_x, .y = utils.to_float(SCREEN_SIZE.y) };
            rl.drawLineEx(start_pos, end_pos, LINES_THIKNESS, LINES_COLOR);
        }

        var j: i32 = 0;
        while (j <= self.world.height) : (j += 1) {
            const pos_y: f32 = utils.to_float(j) * self.block_size.y;
            const start_pos = rl.Vector2{ .x = 0, .y = pos_y };
            const end_pos = rl.Vector2{ .x = utils.to_float(SCREEN_SIZE.x), .y = pos_y };
            rl.drawLineEx(start_pos, end_pos, LINES_THIKNESS, LINES_COLOR);
        }
    }

    pub fn draw_apples(self: *Game) void {
        for (self.apple_manager.list.items) |apple| {
            const pos = self.get_grid_pos_offset(apple.pos);
            const radius = utils.min(self.block_size.x, self.block_size.y) / 2.0;
            rl.drawCircle(utils.to_int(pos.x), utils.to_int(pos.y), radius, APPLE_COLOR);
        }
    }

    pub fn draw_snake(self: *Game) void {
        var size_factor: f32 = BODY_FACTOR;
        const size_step: f32 = 0.4 / utils.to_float(@as(i32, @intCast(self.snake.segments.items.len)));
        for (self.snake.segments.items) |seg| {
            const pos_shift = (1.0 - size_factor) / 2.0;
            var pos = self.get_grid_pos(seg.pos);

            pos.x += pos_shift * self.block_size.x;
            pos.y += pos_shift * self.block_size.y;

            const size = rl.Vector2{
                .x = self.block_size.x * size_factor,
                .y = self.block_size.y * size_factor,
            };

            size_factor -= size_step;

            rl.drawRectangleV(pos, size, SNAKE_COLOR);
        }
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        rl.clearBackground(BACKGROUND_COLOR);
        defer rl.endDrawing();

        if (rl.isWindowResized()) {
            SCREEN_SIZE.x = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenWidth())) * rl.getWindowScaleDPI().x));
            SCREEN_SIZE.y = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * rl.getWindowScaleDPI().y));
        }

        self.block_size = rl.Vector2{
            .x = @as(f32, @floatFromInt(SCREEN_SIZE.x)) / @as(f32, @floatFromInt(self.world.width)),
            .y = @as(f32, @floatFromInt(SCREEN_SIZE.y)) / @as(f32, @floatFromInt(self.world.height)),
        };

        self.draw_grid();
        self.draw_apples();
        self.draw_snake();
    }
};

const config = rl.ConfigFlags{
    .window_resizable = true,
    .vsync_hint = true,
    .window_highdpi = true,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    rl.setConfigFlags(config);
    rl.initWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, TITLE);

    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var game = try Game.init(allocator);
    defer game.deinit();

    while (!rl.windowShouldClose()) {
        game.hanle_input();
        try game.update();
        game.draw();
    }
}
