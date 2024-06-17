const std = @import("std");

const Ulid = @This();

bytes: [16]u8,

pub fn new() Ulid {
    var ulid: Ulid = undefined;

    const ts: u48 = @intCast(std.time.milliTimestamp());

    std.mem.writeInt(u48, ulid.bytes[0..6], ts, .big);
    std.crypto.random.bytes(ulid.bytes[6..]);

    return ulid;
}

pub const ParseStringError = error{
    InvalidLength,
    InvalidUlidChar,
    OutOfBounds,
};

pub fn parseString(str: []const u8) !Ulid {
    if (str.len != 26) return ParseStringError.InvalidLength;
    var ulid: Ulid = undefined;

    var fixed = std.io.fixedBufferStream(&ulid.bytes);
    var writer = std.io.bitWriter(.big, fixed.writer());

    if (charB32Index(str[0])) |i| {
        if (i >= 8) return error.OutOfBounds;
        const sm: u3 = @intCast(i);
        try writer.writeBits(sm, 3);
    } else return ParseStringError.InvalidUlidChar;

    for (str[1..]) |ch| {
        if (charB32Index(ch)) |i| {
            try writer.writeBits(i, 5);
        } else return ParseStringError.InvalidUlidChar;
    }

    return ulid;
}

pub fn timestamp(self: Ulid) u48 {
    return std.mem.readInt(u48, self.bytes[0..6], .big);
}

pub fn data(self: Ulid) [10]u8 {
    return self.bytes[6..];
}

const b32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
pub fn toString(self: Ulid) [26]u8 {
    var fixed = std.io.fixedBufferStream(&self.bytes);
    var reader = std.io.bitReader(.big, fixed.reader());

    var str: [26]u8 = undefined;
    str[0] = b32[reader.readBitsNoEof(u3, 3) catch unreachable];
    for (1..26) |i| {
        str[i] = b32[reader.readBitsNoEof(u5, 5) catch unreachable];
    }

    return str;
}

inline fn charB32Index(ch: u8) ?u5 {
    return @intCast(switch (ch) {
        '0'...'9' => ch - '0' + 0, // 10
        'A'...'H' => ch - 'A' + 10, // 8
        'J', 'K' => ch - 'J' + 18, // 2
        'M', 'N' => ch - 'M' + 20, // 2
        'P'...'T' => ch - 'P' + 22, // 5
        'V'...'Z' => ch - 'V' + 27, // 5
        else => return null,
    });
}

test "init" {
    const start: u48 = @intCast(std.time.milliTimestamp());
    const ulid = Ulid.new();
    const end = ulid.timestamp();

    // ive been told never to test timings... oh well.
    try std.testing.expect(end >= start);
    try std.testing.expect(end - start < 1000);

    const str = ulid.toString();

    const parsed_ulid = try Ulid.parseString(&str);
    try std.testing.expectEqualSlices(u8, &ulid.bytes, &parsed_ulid.bytes);
}

test "max" {
    const ulid = Ulid{
        .bytes = [_]u8{0xFF} ** 16,
    };
    const str = ulid.toString();

    try std.testing.expectEqualStrings("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", &str);
}

test "errors" {
    const bad_ulid = "8ZZZZZZZZZZZZZZZZZZZZZZZZZ";

    if (Ulid.parseString(bad_ulid)) |_| {
        unreachable;
    } else |err| {
        try std.testing.expectEqual(Ulid.ParseStringError.OutOfBounds, err);
    }

    const bad_ulid_2 = "ZZZZ";
    if (Ulid.parseString(bad_ulid_2)) |_| {
        unreachable;
    } else |err| {
        try std.testing.expectEqual(Ulid.ParseStringError.InvalidLength, err);
    }

    const bad_ulid_3 = "7ZZZZZZZZZZZZZZZZZZZZZZZIZ";
    if (Ulid.parseString(bad_ulid_3)) |_| {
        unreachable;
    } else |err| {
        try std.testing.expectEqual(Ulid.ParseStringError.InvalidUlidChar, err);
    }
}
