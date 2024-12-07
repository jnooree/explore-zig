const std = @import("std");

const utils = @import("utils");

const Data = std.ArrayList(i32);
const Map = std.AutoHashMap(i32, i32);

fn first(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var left = Data.init(allocator);
    var right = Data.init(allocator);

    var buf: [1024]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        try left.append(try std.fmt.parseInt(i32, it.next().?, 10));
        try right.append(try std.fmt.parseInt(i32, it.next().?, 10));
    }

    std.mem.sort(i32, left.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, comptime std.sort.asc(i32));

    var total: u32 = 0;
    for (left.items, right.items) |l, r| {
        total += @abs(l - r);
    }

    std.log.info("{d}", .{total});
}

fn second(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var left = Map.init(allocator);
    var right = Map.init(allocator);

    var buf: [1024]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        const lcnt = try left.getOrPut(try std.fmt.parseInt(i32, it.next().?, 10));
        if (!lcnt.found_existing)
            lcnt.value_ptr.* = 0;
        lcnt.value_ptr.* += 1;

        const rcnt = try right.getOrPut(try std.fmt.parseInt(i32, it.next().?, 10));
        if (!rcnt.found_existing)
            rcnt.value_ptr.* = 0;
        rcnt.value_ptr.* += 1;
    }

    var total: u64 = 0;
    var lit = left.iterator();
    while (lit.next()) |lp| {
        const r = right.get(lp.key_ptr.*);
        if (r != null)
            total += @intCast(lp.key_ptr.* * lp.value_ptr.* * r.?);
    }

    std.log.info("{d}", .{total});
}

pub fn main() !void {
    try utils.dispatch(.{ first, second });
}
