const rl = @import("raylib");
const std = @import("std");

const Direction = @import("direction.zig").Direction;
const Vec2 = @import("vec2.zig").Vec2;

const Apples = @import("apple/apples.zig").Apples;
const Segment = @import("snake/segment.zig").Segment;
const Snake = @import("snake/snake.zig").Snake;
const World = @import("world.zig").World;

const GameConfig = @import("game_config.zig").GameConfig;

const Allocator = std.mem.Allocator;

const Game = struct {
    gcfg: GameConfig = undefined,

    world: *World = undefined,
    snake: *Snake = undefined,
    apples: *Apples = undefined,

    runtime_screen_size: Vec2 = undefined,
    block_size: f32 = 0.0,

    last_frame_time: i64 = undefined,

    timer: i64 = 0,

    pub fn init(allocator: Allocator, gcfg: GameConfig) !Game {
        const world = try allocator.create(World);
        world.* = World.init(gcfg.init_world_size);

        const snake = try allocator.create(Snake);
        snake.* = Snake.init(gcfg);

        const apples = try allocator.create(Apples);
        apples.* = Apples.init(snake, world, gcfg);

        return .{
            .gcfg = gcfg,
            .world = world,
            .snake = snake,
            .apples = apples,
            .last_frame_time = std.time.milliTimestamp(),
            .runtime_screen_size = gcfg.start_screen_size,
        };
    }

    pub fn deinit(self: *Game, allocator: Allocator) void {
        self.apples.deinit(allocator);
        self.snake.deinit(allocator);

        allocator.destroy(self.apples);
        allocator.destroy(self.snake);
        allocator.destroy(self.world);
    }

    pub fn start(self: *Game, allocator: Allocator) !void {
        try self.restart(allocator);
    }

    pub fn restart(self: *Game, allocator: Allocator) !void {
        try self.snake.restart(allocator);
        try self.apples.restart(allocator);
    }

    pub fn hanleInput(self: *Game) void {
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

    pub fn checkSnake(self: *Game) bool {
        const head = self.snake.segments.items[0];
        if (head.pos.x >= self.world.width or head.pos.x < 0 or head.pos.y >= self.world.height or head.pos.y < 0) {
            return true;
        }

        for (self.snake.segments.items, 0..) |item, index| {
            if (index != 0 and Vec2.isEqual(item.pos, head.pos)) {
                return true;
            }
        }

        return false;
    }

    pub fn update(self: *Game, allocator: Allocator) !void {
        const delta_time: i64 = std.time.milliTimestamp() - self.last_frame_time;
        self.timer += delta_time;

        const tick_time = std.time.ms_per_s * 0.25;
        if (self.timer >= tick_time) {
            const last_segment = self.snake.segments.items[self.snake.segments.items.len - 1];
            self.snake.move();
            if (self.checkSnake()) {
                try self.restart(allocator);
                return;
            }

            const found_apple_idx = self.apples.checkApples();
            if (found_apple_idx != -1) {
                // funny type shenanigans :D
                const apple_idx = @as(usize, @intCast(found_apple_idx));
                self.apples.list.items[apple_idx].pos = self.apples.getPosition();
                try self.snake.grow(allocator, last_segment);
            }
            self.timer = 0;
        }

        self.last_frame_time = std.time.milliTimestamp();
    }

    fn getGridPosOffset(self: *Game, pos: Vec2) rl.Vector2 {
        const rl_pos = pos.asRLVec2();

        return rl.Vector2{
            .x = self.block_size / 2.0 + rl_pos.x * self.block_size,
            .y = self.block_size / 2.0 + rl_pos.y * self.block_size,
        };
    }

    fn getGridPos(self: *Game, pos: Vec2) rl.Vector2 {
        const rl_pos = pos.asRLVec2();
        return rl.Vector2{
            .x = rl_pos.x * self.block_size,
            .y = rl_pos.y * self.block_size,
        };
    }

    pub fn drawGrid(self: *Game) void {
        var i: i32 = 0;
        while (i <= self.world.width) : (i += 1) {
            const pos_x = @as(f32, @floatFromInt(i)) * self.block_size;
            const start_pos = rl.Vector2{ .x = pos_x, .y = 0 };
            const end_pos = rl.Vector2{
                .x = pos_x,
                .y = @as(f32, @floatFromInt(self.runtime_screen_size.y)),
            };
            rl.drawLineEx(
                start_pos,
                end_pos,
                self.gcfg.line_thikness,
                self.gcfg.lines_color,
            );
        }

        var row: i32 = 0;
        while (row <= self.world.height) : (row += 1) {
            const pos_y: f32 = @as(f32, @floatFromInt(row)) * self.block_size;
            const start_pos = rl.Vector2{
                .x = 0,
                .y = pos_y,
            };
            const end_pos = rl.Vector2{
                .x = @as(f32, @floatFromInt(self.runtime_screen_size.x)),
                .y = pos_y,
            };
            rl.drawLineEx(
                start_pos,
                end_pos,
                self.gcfg.line_thikness,
                self.gcfg.lines_color,
            );
        }
    }

    pub fn drawApples(self: *Game) void {
        for (self.apples.list.items) |apple| {
            const pos = self.getGridPosOffset(apple.pos);
            const radius = self.block_size / 2.0;
            rl.drawCircle(
                @as(i32, @intFromFloat(pos.x)),
                @as(i32, @intFromFloat(pos.y)),
                radius,
                self.gcfg.apple_color,
            );
        }
    }

    pub fn drawSnake(self: *Game) void {
        var size_factor: f32 = self.gcfg.reduce_size_factor;
        const size_step: f32 = 0.4 / @as(f32, @floatFromInt(self.snake.segments.items.len));
        for (self.snake.segments.items) |seg| {
            const pos_shift = (1.0 - size_factor) / 2.0;
            var pos = self.getGridPos(seg.pos);

            pos.x += pos_shift * self.block_size;
            pos.y += pos_shift * self.block_size;

            const size = rl.Vector2{
                .x = self.block_size * size_factor,
                .y = self.block_size * size_factor,
            };

            size_factor -= size_step;

            rl.drawRectangleV(pos, size, self.gcfg.snake_color);
        }
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(self.gcfg.background_color);
        if (rl.isWindowResized()) {
            self.runtime_screen_size.x = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenWidth())) * rl.getWindowScaleDPI().x));
            self.runtime_screen_size.y = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * rl.getWindowScaleDPI().y));
        }
        const x_block = @as(f32, @floatFromInt(self.runtime_screen_size.x)) / @as(f32, @floatFromInt(self.world.width));
        const y_block = @as(f32, @floatFromInt(self.runtime_screen_size.y)) / @as(f32, @floatFromInt(self.world.height));
        self.block_size = @min(x_block, y_block);

        self.drawGrid();
        self.drawApples();
        self.drawSnake();
    }
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    const config = rl.ConfigFlags{
        .window_resizable = true,
        .vsync_hint = true,
        .window_highdpi = true,
        .msaa_4x_hint = true,
    };

    const gcfg = @as(GameConfig, @import("game_config.zon"));

    rl.setConfigFlags(config);
    rl.initWindow(
        gcfg.start_screen_size.x,
        gcfg.start_screen_size.y,
        gcfg.title,
    );

    defer rl.closeWindow();
    rl.setTargetFPS(gcfg.target_fps);

    var game = try Game.init(allocator, gcfg);
    defer game.deinit(allocator);

    try game.start(allocator);

    while (!rl.windowShouldClose()) {
        game.hanleInput();
        try game.update(allocator);
        game.draw();
    }
}
