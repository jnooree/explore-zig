const std = @import("std");
const mem = std.mem;

const utils = @import("utils");

const Data = std.ArrayList(i32);

fn parseStrict(token: ?[]const u8) ?u64 {
    const content = token orelse return null;

    if (content.len < 1 or content.len > 3)
        return null;

    for (content) |c| {
        if (c < '0' or c > '9')
            return null;
    }

    return std.fmt.parseInt(u64, content, 10) catch null;
}

fn first(allocator: mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var total: u64 = 0;
    var buf: [4096]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var begin: usize = 0;

        while (mem.indexOfPos(u8, line, begin, "mul(")) |left| {
            const right = mem.indexOfScalarPos(u8, line, left + 4, ')') orelse
                break;
            begin = right + 1;

            const expr = line[left + 4 .. right];
            var it = mem.splitScalar(u8, expr, ',');
            const a = parseStrict(it.next());
            const b = parseStrict(it.next());
            if (a == null or b == null or it.next() != null) {
                begin = left + 4;
                continue;
            }

            total += a.? * b.?;
        }
    }

    std.log.info("{d}", .{total});

    _ = allocator;
}

fn second(allocator: mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var total: u64 = 0;
    var enabled = true;

    var buf: [4096]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var begin: usize = 0;

        while (mem.indexOfScalarPos(u8, line, begin, '(')) |left| {
            if (left >= 2 and mem.startsWith(u8, line[left - 2 ..], "do()")) {
                enabled = true;
                begin = left + 2;
                continue;
            }
            if (left >= 5 and mem.startsWith(u8, line[left - 5 ..], "don't()")) {
                enabled = false;
                begin = left + 2;
                continue;
            }
            if (!enabled or left < 3 or
                !mem.startsWith(u8, line[left - 3 ..], "mul("))
            {
                begin = left + 1;
                continue;
            }

            const right = mem.indexOfScalarPos(u8, line, left + 1, ')') orelse break;
            begin = right + 1;

            const expr = line[left + 1 .. right];
            var it = mem.splitScalar(u8, expr, ',');
            const a = parseStrict(it.next());
            const b = parseStrict(it.next());
            if (a == null or b == null or it.next() != null) {
                begin = left + 4;
                continue;
            }

            total += a.? * b.?;
        }
    }

    std.log.info("{d}", .{total});

    _ = allocator;
}

pub fn main() !void {
    try utils.dispatch(.{ first, second });
}
