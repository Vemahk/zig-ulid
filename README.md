# zig-ulid

A small [zig](https://ziglang.org/) implementation of [Ulid](https://github.com/ulid/spec).

Honestly, I was surprised at how small the spec was.  I probably missed something.

Tested with zig 0.12.0 and 0.13.0.  If not for b.path(), it would probably work for 0.11.0.

## Features

- [x] No allocations
- [x] To/From String
- [x] Monotonicity

## Examples

```zig

// Default usage
const Ulid = @import("ulid");
const id = Ulid.new();
const str = id.toString(); // e.g. "01J0J510YN2KZV7APEE1BQ8BYP"
const copy = try Ulid.parseString(str); // == id

const epoch_ms: u48 = ulid.timestamp();
const random_data: [10]u8 = ulid.data();

// Monotonic
var monotonic = Ulid.MonotonicFactory{};
const ulid_1 = try monotonic.next(); // e.g. "01J0JBY3EXAVVZ227VE93QJD2M"
const ulid_2 = try monotonic.next(); // e.g. "01J0JBY3EXAVVZ227VE93QJD2N"

// or using the global factory (not recommended but available)
const ulid_3 = try Ulid.newMonotonic(); // e.g. "01J0JC10BFE2CJB7M2SZXX98NH"
const ulid_4 = try Ulid.newMonotonic(); // e.g. "01J0JC10BFE2CJB7M2SZXX98NJ"

```

## Use

build.zig.zon

```
.ulid = .{
    .url = "https://github.com/Vemahk/zig-ulid/archive/<git_commit_hash>.tar.gz",
},
```

build.zig

```zig

const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});

const root = b.path("src/main.zig");
const exe = b.addExecutable(.{
    .name = "your_project",
    .root_source_file = root,
    .target = target,
    .optimize = optimize,
});

const dep_opts = .{ .target = target, .optimize = optimize };
const ulid_mod = b.dependency("ulid", dep_opts).module("ulid");
exe.root_module.addImport("ulid", ulid_mod);

b.installArtifact(exe);

```

Or something like that.
