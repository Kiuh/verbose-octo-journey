const std = @import("std");
const zlinter = @import("zlinter");

const Build = std.Build;

const rules = .{
    .{
        .rule = zlinter.BuiltinLintRule.field_naming,
        .config = .{
            .error_field_min_len = .{
                .severity = .off,
                .len = 0,
            },
            .enum_field_min_len = .{
                .severity = .off,
                .len = 0,
            },
            .struct_field_min_len = .{
                .severity = .off,
                .len = 0,
            },
            .union_field_min_len = .{
                .severity = .off,
                .len = 0,
            },
        },
    },
    .{
        .rule = zlinter.BuiltinLintRule.field_ordering,
        .config = .{
            .union_field_order = .{
                .order = .alphabetical_ascending,
                .severity = .off,
            },
            .enum_field_order = .{
                .order = .alphabetical_ascending,
                .severity = .off,
            },
            .struct_field_order = .{
                .order = .alphabetical_ascending,
                .severity = .off,
            },
        },
    },
    .{
        .rule = zlinter.BuiltinLintRule.require_doc_comment,
        .config = .{
            .file_severity = .off,
            .public_severity = .off,
            .private_severity = .off,
        },
    },
    .{
        .rule = zlinter.BuiltinLintRule.no_undefined,
        .config = .{
            .severity = .off,
        },
    },
    .{
        .rule = zlinter.BuiltinLintRule.no_inferred_error_unions,
        .config = .{
            .severity = .off,
        },
    },
};

pub fn build(b: *Build) void {
    const lint_cmd = b.step("lint", "Lint source code");
    const build_all = b.step("all", "Build everything");

    lint_cmd.dependOn(step: {
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
