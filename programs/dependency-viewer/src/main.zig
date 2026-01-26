const std = @import("std");

pub fn main() !void {
    std.debug.print("Pass directory with any project to see it dependency graph.\n", .{});
}
