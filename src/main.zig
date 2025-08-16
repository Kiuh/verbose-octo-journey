const std = @import("std");
const rl = @import("raylib");

const rand = std.crypto.random;

// Default aliases
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn to_int(in: f32) i32 {
    return @as(i32, @intFromFloat(in));
}

pub fn to_float(in: i32) f32 {
    return @as(f32, @floatFromInt(in));
}

// Raylib types
const Color = rl.Color;

// Custom types
const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn create(x: i32, y: i32) Vec2 {
        return .{
            .x = x,
            .y = y,
        };
    }

    pub fn isEqual(a: Vec2, b: Vec2) bool {
        return a.x == b.x and a.y == b.y;
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn min(self: *Vec2) i32 {
        if (self.x < self.y) {
            return self.x;
        } else {
            return self.y;
        }
    }
};

pub fn min(x: f32, y: f32) f32 {
    if (x < y) {
        return x;
    } else {
        return y;
    }
}

const Direction = enum {
    none,
    up,
    down,
    right,
    left,
};

// System constants
const TITLE = "Collaboration zig's snake game";
var SCREEN_WIDTH: i32 = 800;
var SCREEN_HEIGHT: i32 = 400;

// Game constants
const START_SNAKE_LENGTH = 3;
const COUNT_OF_APPLES = 8;
const SEGMENT_SIZE = 1;
const SNAKE_INIT_POS = Vec2{ .x = 0, .y = 0 };

const WORLD_INIT_HEIGHT = 10;
const WORLD_INIT_WIDTH = 20;

// Render constants
const BACKGROUND_COLOR = Color.white;

const LINES_COLOR = Color.black;
const LINES_THIKNESS: f32 = 2.0;

const APPLE_COLOR = Color.red;

const BODY_FACTOR = 0.8;
const SNAKE_COLOR = Color.green;

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

// Utility
pub fn direction_to_vector(dir: Direction) Vec2 {
    switch (dir) {
        Direction.up => {
            return Vec2{ .x = 0, .y = -SEGMENT_SIZE };
        },
        Direction.down => {
            return Vec2{ .x = 0, .y = SEGMENT_SIZE };
        },
        Direction.right => {
            return Vec2{ .x = SEGMENT_SIZE, .y = 0 };
        },
        Direction.left => {
            return Vec2{ .x = -SEGMENT_SIZE, .y = 0 };
        },
        Direction.none => {
            return Vec2{ .x = 0, .y = 0 };
        },
    }
}

const Segment = struct {
    pos: Vec2 = Vec2{},
};

const Snake = struct {
    segments: ArrayList(Segment) = undefined,
    length: usize = 0,
    last_movement_dir: Direction = Direction.down,
    input_direction: Direction = Direction.none,

    pub fn init(allocator: Allocator, pos: Vec2) !Snake {
        var snake = Snake{};
        snake.segments = ArrayList(Segment).init(allocator);
        snake.length = START_SNAKE_LENGTH;
        for (0..snake.length) |idx| {
            const seg = Segment{
                .pos = Vec2{
                    .x = pos.x,
                    .y = pos.y + SEGMENT_SIZE * @as(i32, @intCast(idx)),
                },
            };
            try snake.segments.append(seg);
        }

        return snake;
    }
    pub fn deinit(self: *Snake) void {
        self.segments.deinit();
    }

    pub fn grow(self: *Snake, growth_direction: Direction) !void {
        const offset = direction_to_vector(growth_direction);
        const last_pos = self.segments.items[self.length - 1].pos;
        const new_pos = Vec2.add(last_pos, offset);
        try self.segments.append(Segment{ .pos = new_pos });
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
                self.segments.items[i].pos = Vec2.add(segment.pos, direction_to_vector(self.last_movement_dir));
                self.input_direction = Direction.none;
                pos_to_set = prev_pos;
                continue;
            }
            self.segments.items[i].pos = pos_to_set;
            pos_to_set = prev_pos;
        }
    }
};

const AppleManagement = struct {
    list: ArrayList(Apple) = undefined,

    pub fn init(allocator: Allocator) !AppleManagement {
        var applesManagement = AppleManagement{};
        applesManagement.list = ArrayList(Apple).init(allocator);
        for (0..COUNT_OF_APPLES) |idx| {
            const apple: Apple = Apple{ .pos = Vec2{
                .x = @as(i32, @intCast(idx)) * SEGMENT_SIZE,
                .y = @as(i32, @intCast(idx)) * SEGMENT_SIZE,
            } };
            try applesManagement.list.append(apple);
        }

        return applesManagement;
    }

    pub fn get_position(self: *AppleManagement, snake: *Snake, world: *World) Vec2 {
        // TODO
        var isFinded = false;

        var candidate: Vec2 = Vec2{
            .x = @mod(rand.int(i32), world.width),
            .y = @mod(rand.int(i32), world.height),
        };

        while (!isFinded) {
            var isInApple = false;
            var isInSnake = false;

            for (self.list.items) |apple| {
                if (Vec2.isEqual(candidate, apple.pos)) {
                    isInApple = true;
                }
            }
            for (snake.segments.items) |item| {
                if (Vec2.isEqual(candidate, item.pos)) {
                    isInSnake = true;
                }
            }
            if (!isInSnake and !isInApple) {
                isFinded = true;
            } else {
                candidate = Vec2{
                    .x = candidate.x + 1,
                    .y = candidate.y + 1,
                };
            }
        }

        return candidate;
    }

    pub fn check_apples(self: *AppleManagement, snake: *Snake, world: *World) bool {
        const head = snake.segments.items[0];
        for (self.list.items, 0..) |apple, i| {
            if (Vec2.isEqual(apple.pos, head.pos)) {
                self.list.items[i].pos = self.get_position(snake, world);
                return true;
            }
        }
        return false;
    }

    pub fn deinit(self: *AppleManagement) void {
        self.list.deinit();
    }
};

const Apple = struct {
    pos: Vec2 = Vec2{},
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
        const apple_manager = try AppleManagement.init(allocator);

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

    pub fn update(self: *Game) !void {
        const delta_time: i64 = std.time.milliTimestamp() - self.last_frame_time;
        self.timer += delta_time;

        if (self.timer >= std.time.ms_per_s) {
            self.snake.move();
            const apple_found = AppleManagement.check_apples(&self.apple_manager, &self.snake, &self.world);
            if (apple_found) {
                try self.snake.grow(Direction.down);
            }
            self.timer = 0;
        }

        self.last_frame_time = std.time.milliTimestamp();
    }

    fn get_grid_pos_offset(self: *Game, pos: Vec2) rl.Vector2 {
        return rl.Vector2{
            .x = self.block_size.x / 2.0 + to_float(pos.x) * self.block_size.x,
            .y = self.block_size.y / 2.0 + to_float(pos.x) * self.block_size.y,
        };
    }

    fn get_grid_pos(self: *Game, pos: Vec2) rl.Vector2 {
        return rl.Vector2{
            .x = to_float(pos.x) * self.block_size.x,
            .y = to_float(pos.y) * self.block_size.y,
        };
    }

    pub fn draw_grid(self: *Game) void {
        var i: i32 = 1;
        while (i <= self.world.width) : (i += 1) {
            const pos_x = to_float(i) * self.block_size.x;
            const start_pos = rl.Vector2{ .x = pos_x, .y = 0 };
            const end_pos = rl.Vector2{ .x = pos_x, .y = to_float(SCREEN_HEIGHT) };
            rl.drawLineEx(start_pos, end_pos, LINES_THIKNESS, LINES_COLOR);
        }

        var j: i32 = 1;
        while (j <= self.world.height) : (j += 1) {
            const pos_y: f32 = to_float(j) * self.block_size.y;
            const start_pos = rl.Vector2{ .x = 0, .y = pos_y };
            const end_pos = rl.Vector2{ .x = to_float(SCREEN_WIDTH), .y = pos_y };
            rl.drawLineEx(start_pos, end_pos, LINES_THIKNESS, LINES_COLOR);
        }
    }

    pub fn draw_apples(self: *Game) void {
        for (self.apple_manager.list.items) |apple| {
            const pos = self.get_grid_pos_offset(apple.pos);
            const radius = min(self.block_size.x, self.block_size.y) / 2.0;
            rl.drawCircle(to_int(pos.x), to_int(pos.y), radius, APPLE_COLOR);
        }
    }

    pub fn draw_snake(self: *Game) void {
        std.debug.print("{}\n", .{self.snake.length});
        for (self.snake.segments.items) |seg| {
            std.debug.print("{}\n", .{seg.pos});
            const pos_shift = (1.0 - BODY_FACTOR) / 2.0;
            var pos = self.get_grid_pos(seg.pos);

            pos.x += pos_shift * self.block_size.x;
            pos.y += pos_shift * self.block_size.y;

            const size = rl.Vector2{ .x = self.block_size.x * BODY_FACTOR, .y = self.block_size.y * BODY_FACTOR };
            rl.drawRectangleV(pos, size, SNAKE_COLOR);
        }
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        rl.clearBackground(BACKGROUND_COLOR);
        defer rl.endDrawing();

        SCREEN_WIDTH = rl.getScreenWidth() * 2;
        SCREEN_HEIGHT = rl.getScreenHeight() * 2;

        self.block_size = rl.Vector2{
            .x = to_float(@divTrunc(SCREEN_WIDTH, self.world.width)),
            .y = to_float(@divTrunc(SCREEN_HEIGHT, self.world.height)),
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
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE);

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
