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
    // from https://ziglang.org/documentation/master/#Choosing-an-Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const hdf5_install_o = b.option(
        []const u8, // Type: string
        "hdf5-install", // Option name (will be used as -Dmy_path=...)
        "Specifies a path to HDF5 install path", // Description
    );
    const medfile_install_o = b.option(
        []const u8,
        "medfile-install",
        "Specifies a path to MEDFile install path", // Description
    );

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

    if (hdf5_install_o != null and medfile_install_o != null) {
        const hdf5_install = hdf5_install_o.?;
        const medfile_install = medfile_install_o.?;

        const h5_include = try b.path(hdf5_install).join(allocator, "include");
        const med_include = try b.path(medfile_install).join(allocator, "include");

        const h5_path = try b.path(hdf5_install).join(allocator, "lib");
        const med_path = try b.path(medfile_install).join(allocator, "lib");

        exe.addIncludePath(h5_include);
        exe.addIncludePath(med_include);

        exe.addLibraryPath(h5_path);
        exe.addLibraryPath(med_path);

        exe.linkSystemLibrary("hdf5");
        exe.linkSystemLibrary("medC");
    } else {
        exe.step.dependOn(&b.addFail("Error: mandatory options '-Dhdf5-install' or '-Dmedfile-install' not provided").step);
    }

    b.installArtifact(exe);
}
