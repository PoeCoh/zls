const std = @import("std");
const builtin = @import("builtin");

/// Returns a URI from a path.
/// Caller should free memory
pub fn fromPath(allocator: std.mem.Allocator, path: []const u8) error{OutOfMemory}![]u8 {
    return try std.fmt.allocPrint(
        allocator,
        "{}",
        .{std.Uri{ .scheme = "file", .path = .{ .raw = path } }},
    );
}

/// parses a Uri and return the unescaped path
/// Caller should free memory
pub fn parse(allocator: std.mem.Allocator, str: []const u8) (std.Uri.ParseError || error{OutOfMemory})![]u8 {
    const uri = try std.Uri.parse(str);
    if (!std.mem.eql(u8, uri.scheme, "file")) return error.InvalidFormat;
    return try std.fmt.allocPrint(allocator, "{raw}", .{uri.path});
}
