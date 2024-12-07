const std = @import("std");

fn callSolution(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    solution: *const fn (std.mem.Allocator, std.fs.File) anyerror!void,
) !void {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    try solution(allocator, file);
}

pub fn dispatch(
    solutions: [2]*const fn (std.mem.Allocator, std.fs.File) anyerror!void,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    if (args.len > 2) {
        const problem = try std.fmt.parseInt(usize, args[2], 10);
        try callSolution(allocator, args[1], solutions[problem - 1]);
        return;
    }

    std.log.info("---", .{});
    for (solutions) |solution| {
        try callSolution(allocator, args[1], solution);
        std.log.info("---", .{});
    }
}
