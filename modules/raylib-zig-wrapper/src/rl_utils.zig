const raylib = @import("raylib");

pub fn init_window(width: u32, height: u32, title: []const u8) !void {
    try raylib.init_window(width, height, title);
}

pub fn close_window() !void {
    try raylib.close_window();
}

pub fn should_close() bool {
    return raylib.should_close();
}
