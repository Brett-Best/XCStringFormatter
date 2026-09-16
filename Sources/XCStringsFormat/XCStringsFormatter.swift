import Foundation
import XCStringsParserBridge

enum XCStringsFormatError: Error, CustomStringConvertible, Sendable {
    case noInputs
    case inputNotFound(path: String)
    case fileListReadFailed(path: String, detail: String)
    case directoryReadFailed(path: String)
    case inputReadFailed(path: String, detail: String)
    case parseFailed(path: String, detail: String)
    case serializeFailed(path: String, detail: String)
    case writeFailed(path: String, detail: String)

    var description: String {
        switch self {
        case .noInputs:
            "provide at least one .xcstrings file, directory, or stdin"
        case let .inputNotFound(path):
            "input does not exist: \(path)"
        case let .fileListReadFailed(path, detail):
            "could not read file list \(path): \(detail)"
        case let .directoryReadFailed(path):
            "could not enumerate directory: \(path)"
        case let .inputReadFailed(path, detail):
            "\(path): could not read input: \(detail)"
        case let .parseFailed(path, detail):
            "\(path): Xcode could not parse the string catalog: \(detail)"
        case let .serializeFailed(path, detail):
            "\(path): Xcode could not serialize the string catalog: \(detail)"
        case let .writeFailed(path, detail):
            "\(path): could not write output: \(detail)"
        }
    }
}

struct XCStringsFormatResult {
    let input: Data
    let output: Data

    var changed: Bool {
        input != output
    }
}

struct XCStringsFormatter {
    func formatFile(at url: URL) throws -> XCStringsFormatResult {
        let path = url.path
        let input: Data
        do {
            input = try Data(contentsOf: url)
        } catch {
            throw XCStringsFormatError.inputReadFailed(
                path: path,
                detail: error.localizedDescription
            )
        }

        let catalog: XCStrings
        do {
            catalog = try XCStringsSerialization.xcstrings(
                fromPath: path
            )
        } catch {
            throw XCStringsFormatError.parseFailed(
                path: path,
                detail: error.localizedDescription
            )
        }

        let output: Data
        do {
            output = try XCStringsSerialization.data(
                from: catalog
            )
        } catch {
            throw XCStringsFormatError.serializeFailed(
                path: path,
                detail: error.localizedDescription
            )
        }

        return XCStringsFormatResult(input: input, output: output)
    }

    func formatData(_ input: Data, source: String) throws -> XCStringsFormatResult {
        let catalog: XCStrings
        do {
            catalog = try XCStringsSerialization.xcstrings(
                fromData: input
            )
        } catch {
            throw XCStringsFormatError.parseFailed(
                path: source,
                detail: error.localizedDescription
            )
        }

        let output: Data
        do {
            output = try XCStringsSerialization.data(
                from: catalog
            )
        } catch {
            throw XCStringsFormatError.serializeFailed(
                path: source,
                detail: error.localizedDescription
            )
        }

        return XCStringsFormatResult(input: input, output: output)
    }

    func write(_ data: Data, to url: URL) throws {
        let path = url.path
        do {
            try data.write(
                to: url,
                options: .atomic
            )
        } catch {
            throw XCStringsFormatError.writeFailed(
                path: path,
                detail: error.localizedDescription
            )
        }
    }

    func writeToStandardOutput(_ data: Data) throws {
        try FileHandle.standardOutput.write(contentsOf: data)
    }
}
