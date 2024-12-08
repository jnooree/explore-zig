const std = @import("std");

const utils = @import("utils");

const Data = std.ArrayList(i32);

fn isBad(diff: i32) bool {
    const magn = @abs(diff);
    return magn < 1 or magn > 3;
}

fn first(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var cnt: u32 = 0;
    var buf: [1024]u8 = undefined;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var ok = true;

        var prev = try std.fmt.parseInt(i32, it.next().?, 10);
        var curr = try std.fmt.parseInt(i32, it.next().?, 10);
        const diff = @abs(curr - prev);
        if (isBad(@intCast(diff)))
            continue;

        const asc = curr > prev;
        while (it.next()) |nraw| {
            prev = curr;
            curr = try std.fmt.parseInt(i32, nraw, 10);

            if (isBad(curr - prev) or (curr > prev) != asc) {
                ok = false;
                break;
            }
        }

        if (ok)
            cnt += 1;
    }

    std.log.info("{d}", .{cnt});

    _ = allocator;
}

fn tryRecover(diffs: []const i32) bool {
    var err: i32 = 0;
    var asc = diffs[0] > 0;

    var i: usize = 1;
    if (isBad(diffs[0])) {
        const merge_next = diffs[0] + diffs[1];
        if (isBad(merge_next))
            return false;

        i += 1;
        err += 1;
        asc = merge_next > 0;
    }

    while (i < diffs.len) : (i += 1) {
        const diff = diffs[i];
        if (!isBad(diff) and (diff > 0) == asc)
            continue;

        err += 1;
        if (err > 1)
            return false;

        if (i + 1 == diffs.len)
            break;

        const merge_next = diff + diffs[i + 1];
        if (!isBad(merge_next) and (merge_next > 0) == asc) {
            i += 1;
            continue;
        }

        const merge_prev = diffs[i - 1] + diff;
        if (isBad(merge_prev) or (merge_prev > 0) != asc)
            return false;
    }

    return true;
}

fn verifyRest(diffs: []const i32) bool {
    const asc = diffs[0] > 0;

    for (diffs) |diff| {
        if (isBad(diff) or (diff > 0) != asc)
            return false;
    }

    return true;
}

fn second(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var is = buf_reader.reader();

    var diffs = Data.init(allocator);
    var buf: [1024]u8 = undefined;

    var cnt: u32 = 0;
    while (try is.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        diffs.clearRetainingCapacity();

        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var prev = try std.fmt.parseInt(i32, it.next().?, 10);
        while (it.next()) |tok| {
            const curr = try std.fmt.parseInt(i32, tok, 10);
            try diffs.append(curr - prev);
            prev = curr;
        }

        if (tryRecover(diffs.items) or verifyRest(diffs.items[1..])) {
            cnt += 1;
        }
    }

    std.log.info("{d}", .{cnt});
}

pub fn main() !void {
    try utils.dispatch(.{ first, second });
}
