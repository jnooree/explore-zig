const std = @import("std");
const mem = std.mem;

const utils = @import("utils");

const Data = std.ArrayList([]const u8);

fn isMatch(
    haystack: [][]const u8,
    needle: []const u8,
    row: usize,
    col: usize,
    row_incr: isize,
    col_incr: isize,
) bool {
    var r: isize = @intCast(row);
    var c: isize = @intCast(col);

    for (needle) |ch| {
        if (r < 0 or r >= haystack.len or
            c < 0 or c >= haystack[@intCast(r)].len)
            return false;

        if (haystack[@intCast(r)][@intCast(c)] != ch)
            return false;

        r += row_incr;
        c += col_incr;
    }

    return true;
}

fn first(allocator: mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var data = Data.init(allocator);

    var buf: [1024]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line|
        try data.append(try allocator.dupe(u8, line));

    var cnt: u32 = 0;
    for (data.items, 0..) |row, i| {
        for (row, 0..) |ch, j| {
            if (ch != 'X')
                continue;

            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, -1, -1));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, -1, 1));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, -1, 0));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, 1, 0));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, 0, -1));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, 0, 1));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, 1, -1));
            cnt += @intFromBool(isMatch(data.items, "XMAS", i, j, 1, 1));
        }
    }

    std.log.info("{d}", .{cnt});
}

fn second(allocator: mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var data = Data.init(allocator);

    var buf: [1024]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line|
        try data.append(try allocator.dupe(u8, line));

    var cnt: u32 = 0;
    for (data.items[1..], 1..) |row, i| {
        for (row[1..], 1..) |ch, j| {
            if (ch != 'A')
                continue;

            const ud = isMatch(data.items, "MAS", i - 1, j - 1, 1, 1) or
                isMatch(data.items, "MAS", i + 1, j + 1, -1, -1);
            const du = isMatch(data.items, "MAS", i + 1, j - 1, -1, 1) or
                isMatch(data.items, "MAS", i - 1, j + 1, 1, -1);
            cnt += @intFromBool(ud and du);
        }
    }

    std.log.info("{d}", .{cnt});
}

pub fn main() !void {
    try utils.dispatch(.{ first, second });
}
