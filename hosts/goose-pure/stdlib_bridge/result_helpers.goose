// Unit-ish Try: tag 1 = Ok, 0 = Err (see glue comments).

// fn unit_ok_stdout() -> HostStdoutLineResult {
//     HostStdoutLineResult {
//         p0: 0, p1: 0, p2: 0, tag: 1,
//         _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
//     }
// }

// fn unit_ok_configure() -> HostConfigureArenaResult {
//     HostConfigureArenaResult {
//         p0: 0, p1: 0, p2: 0, tag: 1,
//         _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
//     }
// }

// If glue’s HostMathSinResult / HostOsWriteFileResult / etc. share the same
// field layout as HostStdoutLineResult, copy this pattern per type name.
