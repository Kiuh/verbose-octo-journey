const zlinter = @import("zlinter");
// TODO: perhaps make this a .zon?
pub const LinterRules = .{
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
