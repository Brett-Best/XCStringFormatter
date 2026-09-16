# `xcstrings-format`

This is a SwiftPM executable that links Xcode's private
`XCStringsParser.framework` dynamically. It calls Xcode's
`XCStringsSerialization.xcstringsFromPath:error:` and
`dataFromXCStrings:error:` entry points through a small Objective-C
bridge target, so Swift uses the imported Objective-C class methods directly.
The CLI uses Swift Argument Parser, pinned in `Package.resolved`.

Build it with the active Swift 6.4 toolchain selected by `xcrun`:

```sh
/usr/bin/xcrun swift build
```

## Installation

Consumers should install the command with [Mint](https://github.com/yonaskolb/Mint):

```sh
mint install Brett-Best/XCStringFormatter@main
```

Mint links the `xcstrings-format` executable into `~/.mint/bin` by default;
ensure that directory is on your `PATH`, then invoke it directly:

```sh
xcstrings-format path/to/Localizable.xcstrings
```

The manifest uses
`/Applications/Xcode.app/Contents/SharedFrameworks` by default. SwiftPM reads
`XCSTRINGS_FORMAT_SHARED_FRAMEWORKS` from its process environment when it
evaluates the manifest, so an alternate compatible directory can be selected
for a build or run:

```sh
XCSTRINGS_FORMAT_SHARED_FRAMEWORKS=/path/to/SharedFrameworks \
  /usr/bin/xcrun swift build
```

Standard SwiftPM commands such as `swift package dump-package`, `swift build`,
and `swift run` can be invoked through `xcrun` directly, so they use the user's
active developer tools selection.

To override framework lookup for a run, provide `DYLD_FRAMEWORK_PATH`; the
embedded rpath remains the fallback:

```sh
DYLD_FRAMEWORK_PATH=/path/to/SharedFrameworks \
  /usr/bin/xcrun swift run xcstrings-format path/to/Localizable.xcstrings
```

Format one or more catalogs in place:

```sh
/usr/bin/xcrun swift run xcstrings-format path/to/Localizable.xcstrings
```

The command follows SwiftFormat's positional-input conventions. It accepts
files, directories (recursively finding `.xcstrings` files), `stdin`, and
`--filelist`; `--output`, `--dry-run`, `--lint`, `--verbose`, and `--quiet`
provide the corresponding SwiftFormat-style controls (`--output -` writes to
stdout).

Lint without writing (exit status 1 means a file would change):

```sh
/usr/bin/xcrun swift run xcstrings-format path/to/Localizable.xcstrings --lint
```

The package targets macOS 27, enables SwiftPM's built-in strict memory-safety
setting, and uses its built-in warning settings to treat all Swift and
Objective-C warnings as errors. Swift 6.4's language mode supplies the
features already enabled in Swift 6; the manifest explicitly enables the
remaining upcoming features reported by the compiler. `XCStringsParser.framework`
is private and its Objective-C bridge is not a stable public API, so rebuild
and retest when Xcode changes.

Run the test target with the active developer tools:

```sh
/usr/bin/xcrun swift test
```

The formatter integration test invokes both in-memory and file-based formatting
through Xcode's serializer; it is not limited to testing argument resolution.

The bridge declarations are based on the Objective-C interface emitted by
`ipsw`. To refresh the inventory, dump the framework from the fixed Xcode
installation to a temporary directory:

```sh
binary="/Applications/Xcode.app/Contents/SharedFrameworks/XCStringsParser.framework/Versions/A/XCStringsParser"
ipsw class-dump "$binary" --headers --output /tmp/XCStringsParser-Headers --no-color
```

The dump is an inventory rather than an authoritative source header: Swift
backed Objective-C methods may be emitted with `id` types. The checked-in
bridge keeps the same selectors while refining the Foundation types needed by
Swift.

## License

This project is available under the [MIT License](LICENSE). Xcode's private
`XCStringsParser.framework` is not distributed with this project; a compatible
Xcode installation is required at build and run time.
