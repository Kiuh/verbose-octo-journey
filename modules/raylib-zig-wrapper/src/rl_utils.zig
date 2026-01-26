const raylib = @import("raylib");

pub fn initWindow(width: u32, height: u32, title: []const u8) !void {
    try raylib.init_window(width, height, title);
}

pub fn closeWindow() !void {
    try raylib.close_window();
}

pub fn shoulClose() bool {
    return raylib.should_close();
}
