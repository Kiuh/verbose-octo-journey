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
    grid_cell_size: f32 = 0,
    offset: Vec2 = undefined,

    last_frame_time: i64 = undefined,

    timer: i64 = 0,

    pub fn init(allocator: Allocator, gcfg: GameConfig) !Game {
        const world = try allocator.create(World);
        world.* = World.init(gcfg.init_world_size);

        const snake = try allocator.create(Snake);
        snake.* = Snake.init(gcfg);

        const apples = try allocator.create(Apples);
        apples.* = Apples.init(snake, world, gcfg);

        var game = Game{
            .gcfg = gcfg,
            .world = world,
            .snake = snake,
            .apples = apples,
            .last_frame_time = std.time.milliTimestamp(),
            .runtime_screen_size = gcfg.start_screen_size,
        };
        game.updateWindowSize();

        return game;
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

    fn getPixelPosFromGrid(self: *Game, pos: Vec2, center_pivot: bool) rl.Vector2 {
        const rl_pos = pos.asRLVec2();
        var pivot_offset: f32 = 0;
        if (center_pivot) {
            pivot_offset = self.grid_cell_size / 2.0;
        }
        return rl.Vector2{
            .x = rl_pos.x * self.grid_cell_size + @as(f32, @floatFromInt(self.offset.x)) + pivot_offset,
            .y = rl_pos.y * self.grid_cell_size + @as(f32, @floatFromInt(self.offset.y)) + pivot_offset,
        };
    }

    pub fn drawGrid(self: *Game) void {
        var pos_x: i32 = 0;
        const center_pivot = false;
        while (pos_x <= self.world.width) : (pos_x += 1) {
            const start_pos = self.getPixelPosFromGrid(.{
                .x = pos_x,
                .y = 0,
            }, center_pivot);
            const end_pos = self.getPixelPosFromGrid(.{
                .x = pos_x,
                .y = self.world.height,
            }, center_pivot);
            rl.drawLineEx(
                start_pos,
                end_pos,
                self.gcfg.line_thikness,
                self.gcfg.lines_color,
            );
        }

        var pos_y: i32 = 0;
        while (pos_y <= self.world.height) : (pos_y += 1) {
            const start_pos = self.getPixelPosFromGrid(.{
                .x = 0,
                .y = pos_y,
            }, center_pivot);
            const end_pos = self.getPixelPosFromGrid(.{
                .x = self.world.width,
                .y = pos_y,
            }, center_pivot);
            rl.drawLineEx(
                start_pos,
                end_pos,
                self.gcfg.line_thikness,
                self.gcfg.lines_color,
            );
        }
    }

    pub fn drawApples(self: *Game) void {
        const center_pivot = true;
        for (self.apples.list.items) |apple| {
            const pos = self.getPixelPosFromGrid(apple.pos, center_pivot);
            const radius = self.grid_cell_size / 2.0;
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
        const center_pivot = false;
        for (self.snake.segments.items) |seg| {
            const pos_shift = (1.0 - size_factor) / 2.0;
            // no centering because of custom logic below
            var pos = self.getPixelPosFromGrid(seg.pos, center_pivot);

            pos.x += pos_shift * self.grid_cell_size;
            pos.y += pos_shift * self.grid_cell_size;

            const size = rl.Vector2{
                .x = self.grid_cell_size * size_factor,
                .y = self.grid_cell_size * size_factor,
            };

            size_factor -= size_step;

            rl.drawRectangleV(pos, size, self.gcfg.snake_color);
        }
    }

    fn updateWindowSize(self: *Game) void {
        // compute max allowed grid cell size
        const cell_width = @as(f32, @floatFromInt(self.runtime_screen_size.x)) / @as(f32, @floatFromInt(self.world.width));
        const cell_height = @as(f32, @floatFromInt(self.runtime_screen_size.y)) / @as(f32, @floatFromInt(self.world.height));
        self.grid_cell_size = @min(cell_width, cell_height);

        // update internal screen size (still not sure why we even store it though)
        const block_size = @as(i32, @intFromFloat(self.grid_cell_size));
        self.runtime_screen_size.x = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenWidth())) * rl.getWindowScaleDPI().x));
        self.runtime_screen_size.y = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * rl.getWindowScaleDPI().y));

        // update offset according to the screen size
        self.offset.x = @divTrunc(self.runtime_screen_size.x - self.world.width * block_size, 2);
        self.offset.y = @divTrunc(self.runtime_screen_size.y - self.world.height * block_size, 2);
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(self.gcfg.background_color);
        if (rl.isWindowResized()) {
            self.updateWindowSize();
        }

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
