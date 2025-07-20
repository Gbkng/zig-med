const std = @import("std");
const med = @cImport({
    @cInclude("med.h");
});

pub fn main() !void {
    const filename = "file.med";
    std.debug.print("opening file {s}\n", .{filename});
    const fid = med.MEDfileOpen(filename, med.MED_ACC_CREAT);
    if (fid < 0) {
        std.debug.panic("error opening file {s}\n", .{filename});
    }
}
