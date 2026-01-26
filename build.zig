const std = @import("std");
const zlinter = @import("zlinter");
const rules = @import("configs/linter_rules.zig").LinterRules;

const Build = std.Build;

fn createLintStep(b: *Build) *std.Build.Step {
    var builder = zlinter.builder(b, .{});

    outer: inline for (@typeInfo(zlinter.BuiltinLintRule).@"enum".fields) |f| {
        inline for (rules) |value| {
            if (f.value == @intFromEnum(value.rule)) {
                builder.addRule(.{ .builtin = value.rule }, value.config);
                continue :outer;
            }
        }
        builder.addRule(.{ .builtin = @enumFromInt(f.value) }, .{});
    }

    return builder.build();
}

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_module_options = .{
        .target = target,
        .optimize = optimize,
    };

    const lint_cmd = b.step("lint", "Lint source code");
    const build_cmd = b.step("all", "Build everything");

    const lint_step = createLintStep(b);
    lint_cmd.dependOn(lint_step);

    const apps = .{
        .{
            .dependency_name = "dependency_viewer",
            .artifact_name = "dependency-viewer",
            .run_name = "dv",
        },
        .{
            .dependency_name = "raylib_snake",
            .artifact_name = "raylib-snake",
            .run_name = "snake",
        },
    };

    inline for (apps) |app| {
        const dep = b.lazyDependency(app.dependency_name, default_module_options);
        const artifact = dep.?.artifact(app.artifact_name);
        b.installArtifact(artifact);
        build_cmd.dependOn(&artifact.step);

        const run_step = b.step("run-" ++ app.run_name, "Run the " ++ app.dependency_name);
        const run_cmd = b.addRunArtifact(artifact);
        run_step.dependOn(&run_cmd.step);
    }
}
