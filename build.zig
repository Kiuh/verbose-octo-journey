const std = @import("std");
const zlinter = @import("zlinter");

const Build = std.Build;

pub fn build(b: *Build) void {
    const lint_cmd = b.step("lint", "Lint source code");
    const build_all = b.step("all", "Build everything");

    lint_cmd.dependOn(step: {
        var builder = zlinter.builder(b, .{});
        builder.addRule(.{ .builtin = .field_naming }, .{});
        builder.addRule(.{ .builtin = .declaration_naming }, .{});
        builder.addRule(.{ .builtin = .function_naming }, .{});
        builder.addRule(.{ .builtin = .file_naming }, .{});
        builder.addRule(.{ .builtin = .switch_case_ordering }, .{});
        builder.addRule(.{ .builtin = .no_unused }, .{});
        builder.addRule(.{ .builtin = .no_deprecated }, .{});
        builder.addRule(.{ .builtin = .no_orelse_unreachable }, .{});
        builder.addPaths(.{
            .exclude = &.{b.path("modules/thirdparty/")},
        });
        break :step builder.build();
    });

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
