const Ulid = @import("ulid.zig");
const std = @import("std");

const Self = @This();

last_ulid: Ulid = Ulid.Min,

pub const MonotonicError = error{
    Overflow,
};

pub fn next(self: *Self) MonotonicError!Ulid {
    var ulid: Ulid = self.last_ulid;

    const ts: u48 = @intCast(std.time.milliTimestamp());
    std.mem.writeInt(u48, ulid.bytes[0..6], ts, .big);

    if (std.mem.eql(u8, ulid.bytes[0..6], self.last_ulid.bytes[0..6])) {
        var i: usize = 15;
        while (true) : (i -= 1) {
            if (i < 6) return MonotonicError.Overflow;
            const ov = @addWithOverflow(ulid.bytes[i], 1);
            ulid.bytes[i] = ov[0];
            if (ov[1] == 0) break;
        }
    } else {
        std.crypto.random.bytes(ulid.bytes[6..]);
    }

    self.last_ulid = ulid;
    return ulid;
}

test "monotonic" {
    var factory = Self{};
    const start = std.time.milliTimestamp();
    const next_ms = blk: {
        while (true) {
            const n = std.time.milliTimestamp();
            if (n > start) break :blk n;
        }
    };

    var count: usize = 0;
    while (true) {
        const prev_ulid = factory.last_ulid;
        const ulid = try factory.next();

        if (ulid.timestamp() > next_ms) break;

        try std.testing.expectEqual(ulid.order(prev_ulid), .gt);

        count += 1;
    }

    std.debug.print(
        \\
        \\Test run:
        \\  Start: {d}
        \\  Next: {d}
        \\  Generated {d} ulids in 1 ms.
        \\
    , .{ start, next_ms, count });
}

test "monotonic overflow" {
    const start = std.time.milliTimestamp();
    const next_ms = blk: {
        while (true) {
            const n = std.time.milliTimestamp();
            if (n > start) break :blk n;
        }
    };

    var ulid: Ulid = undefined;

    // force the scenario
    std.mem.writeInt(u48, ulid.bytes[0..6], @intCast(next_ms), .big);
    @memset(ulid.bytes[6..], 0xFF);

    var factory = Self{ .last_ulid = ulid };

    try std.testing.expect(factory.next() == MonotonicError.Overflow);
}
