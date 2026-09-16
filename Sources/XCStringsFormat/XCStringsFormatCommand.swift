import ArgumentParser
import Foundation

@main
struct XCStringsFormatCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcstrings-format",
        abstract: "Format string catalogs with the active Xcode serializer.",
        version: "0.1.0"
    )

    @Argument(help: "String catalog files or directories, or \"stdin\".")
    var paths: [XCStringsFormatInputArgument] = []

    @Option(help: "Path to a file with names of files to process, one per line.")
    var filelist: XCStringsFormatPath?

    @Option(help: "Output path for a single input, or - for stdout.")
    var output: XCStringsFormatOutputArgument?

    @Flag(help: "Run without changing files.")
    var dryRun = false

    @Flag(help: "Return an error for unformatted input.")
    var lint = false

    @Flag(help: "Display detailed processing output.")
    var verbose = false

    @Flag(help: "Suppress non-critical output.")
    var quiet = false

    mutating func run() throws {
        guard !(verbose && quiet) else {
            throw ValidationError("--verbose and --quiet cannot be used together")
        }

        let inputs = try XCStringsFormatInputResolver.resolve(
            paths: paths,
            fileListPath: filelist
        )

        if output != nil, inputs.count != 1 {
            throw ValidationError("--output requires exactly one input")
        }

        let formatter = XCStringsFormatter()
        var anyChanged = false

        for input in inputs {
            switch input {
            case let .file(url):
                let result = try formatter.formatFile(at: url)
                anyChanged = anyChanged || result.changed
                try process(
                    result,
                    source: url,
                    destination: output,
                    formatter: formatter
                )

            case .standardInput:
                let input: Data
                do {
                    input = try FileHandle.standardInput.readToEnd() ?? Data()
                } catch {
                    throw XCStringsFormatError.inputReadFailed(
                        path: "stdin",
                        detail: error.localizedDescription
                    )
                }
                let result = try formatter.formatData(input, source: "stdin")
                anyChanged = anyChanged || result.changed
                try processStandardInput(
                    result,
                    destination: output,
                    formatter: formatter
                )
            }
        }

        if lint, anyChanged {
            throw ExitCode.failure
        }
    }

    private func process(
        _ result: XCStringsFormatResult,
        source: URL,
        destination: XCStringsFormatOutputArgument?,
        formatter: XCStringsFormatter
    ) throws {
        if lint || dryRun {
            if result.changed {
                report("would reformat: \(source.path)")
            } else if verbose {
                report("already formatted: \(source.path)")
            }
            return
        }

        if let destination {
            switch destination {
            case .standardOutput:
                try formatter.writeToStandardOutput(result.output)

            case let .file(url):
                guard result.changed || url != source else {
                    if verbose {
                        report("already formatted: \(source.path)")
                    }
                    return
                }

                try formatter.write(result.output, to: url)
                report("formatted: \(source.path) -> \(url.path)")
            }
            return
        }

        guard result.changed else {
            if verbose {
                report("already formatted: \(source.path)")
            }
            return
        }

        try formatter.write(result.output, to: source)
        report("formatted: \(source.path)")
    }

    private func processStandardInput(
        _ result: XCStringsFormatResult,
        destination: XCStringsFormatOutputArgument?,
        formatter: XCStringsFormatter
    ) throws {
        if lint || dryRun {
            if result.changed {
                report("would reformat: stdin")
            } else if verbose {
                report("already formatted: stdin")
            }
            return
        }

        switch destination {
        case nil, .standardOutput:
            try formatter.writeToStandardOutput(result.output)
        case let .file(url):
            try formatter.write(result.output, to: url)
            report("formatted: stdin -> \(url.path)")
        }
    }

    private func report(_ message: String) {
        guard !quiet else { return }
        print(message)
    }
}
