# zig-ulid

A small [zig](https://ziglang.org/) implementation of [Ulid](https://github.com/ulid/spec).

Honestly, I was surprised at how small the spec was.  I probably missed something.

## Features

- [x] No allocations
- [x] To/From String
- [ ] Monotonicity

## Examples

```zig

const Ulid = @import("ulid");
const id = Ulid.new();
const str = id.toString(); // e.g. "01J0J510YN2KZV7APEE1BQ8BYP"
const copy = try Ulid.parseString(str); // == id

const epoch_ms: u48 = ulid.timestamp();
const random_data: [10]u8 = ulid.data();

```
