const std = @import("std");
const mem = std.mem;
const fs = std.fs;

fn concat(allocator: mem.Allocator, comptime T: type, items: anytype) ![]T {
    var total: usize = 0;
    inline for (items) |item|
        total += item.len;

    var result = try allocator.alloc(T, total);
    var begin: usize = 0;
    inline for (items) |item| {
        const end = begin + item.len;
        @memcpy(result[begin..end], item);
        begin = end;
    }

    return result;
}

fn buildOne(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    utils: *std.Build.Module,
    year: []const u8,
    subpath: []const u8,
) !void {
    const fname = fs.path.stem(subpath);

    const exename = try concat(b.allocator, u8, .{ "aoc-", year, "-", fname });
    defer b.allocator.free(exename);

    const exe = b.addExecutable(.{
        .name = exename,
        .root_source_file = b.path(subpath),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("utils", utils);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".

    const runname = try concat(b.allocator, u8, .{ "run-", fname });
    defer b.allocator.free(runname);

    const rundesc = try concat(b.allocator, u8, .{ "Run ", fname });
    defer b.allocator.free(rundesc);

    const run_step = b.step(runname, rundesc);
    run_step.dependOn(&run_cmd.step);
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const year = b.option([]const u8, "year", "The AOC year") orelse "2024";
    const day = b.option([]const u8, "day", "The AOC day");

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const utils = b.addModule("utils", .{
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    const subdir = try concat(b.allocator, u8, .{ "src/aoc-", year });
    defer b.allocator.free(subdir);

    if (day) |d| {
        const subpath = try concat(b.allocator, u8, .{ subdir, "/day", d, ".zig" });
        defer b.allocator.free(subpath);

        try buildOne(b, target, optimize, utils, year, subpath);
        return;
    }

    var walker = try fs.cwd().openDir(subdir, .{ .iterate = true });
    defer walker.close();

    var it = walker.iterate();
    while (try it.next()) |ent| {
        const subpath = try concat(b.allocator, u8, .{ subdir, "/", ent.name });
        defer b.allocator.free(subpath);

        try buildOne(b, target, optimize, utils, year, subpath);
    }

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
