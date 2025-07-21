const std = @import("std");
const builtin = @import("builtin");

comptime { // check current Zig version is compatible
    const required: std.SemanticVersion = .{
        .major = 0,
        .minor = 14,
        .patch = 0,
    }; // .pre and .build default to null
    const current = builtin.zig_version;
    if (current.order(required) == .lt) {
        const error_message =
            \\Your version of zig is too old ({d}.{d}.{d}).
            \\This project requires at least Zig {d}.{d}.{d}.
            \\You can download a compatible build from: https://ziglang.org/download
        ;
        @compileError(std.fmt.comptimePrint(error_message, .{
            current.major,
            current.minor,
            current.patch,
            required.major,
            required.minor,
            required.patch,
        }));
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = mod,
    });
    exe.linkLibC();
    exe.linkSystemLibrary("hdf5");
    exe.linkSystemLibrary("medC");
    b.installArtifact(exe);
}
