const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rl_utils_mod = b.createModule(.{
        .root_source_file = b.path("src/rl_utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "raylib_zig_wrapper",
        .root_module = rl_utils_mod,
    });

    b.installArtifact(lib);

    const test_mod = b.addTest(.{
        .root_module = rl_utils_mod,
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_mod.step);
}
