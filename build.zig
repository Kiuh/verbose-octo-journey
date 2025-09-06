const std = @import("std");

const Build = std.Build;

pub fn build(b: *Build) void {
    const build_all = b.step("all", "Build everything");

    const dep_viewer = b.dependency(
        "dependency_viewer",
        .{
            .target = b.graph.host,
        },
    );
    const viewer_exe = dep_viewer.artifact("dependency-viewer");
    b.installArtifact(viewer_exe);
    build_all.dependOn(&viewer_exe.step);

    const raylib_snake = b.dependency(
        "raylib_snake",
        .{
            .target = b.graph.host,
        },
    );
    const raylib_snake_exe = raylib_snake.artifact("raylib-snake");
    b.installArtifact(raylib_snake_exe);
    build_all.dependOn(&raylib_snake_exe.step);
}
