import ArgumentParser
import Foundation

struct XCStringsFormatPath: ExpressibleByArgument {
    let url: URL

    init?(argument: String) {
        guard !argument.isEmpty else { return nil }
        let expandedPath = NSString(string: argument).expandingTildeInPath
        url = URL(filePath: expandedPath)
    }
}

enum XCStringsFormatInputArgument: ExpressibleByArgument {
    case file(URL)
    case standardInput

    init?(argument: String) {
        if argument == "stdin" {
            self = .standardInput
        } else if let path = XCStringsFormatPath(argument: argument) {
            self = .file(path.url)
        } else {
            return nil
        }
    }
}

enum XCStringsFormatOutputArgument: ExpressibleByArgument {
    case file(URL)
    case standardOutput

    init?(argument: String) {
        if argument == "-" {
            self = .standardOutput
        } else if let path = XCStringsFormatPath(argument: argument) {
            self = .file(path.url)
        } else {
            return nil
        }
    }
}

enum XCStringsFormatInput {
    case file(URL)
    case standardInput
}

enum XCStringsFormatInputResolver {
    static func resolve(
        paths: [XCStringsFormatInputArgument],
        fileListPath: XCStringsFormatPath?
    ) throws -> [XCStringsFormatInput] {
        var requestedPaths = paths

        if let fileListPath {
            let contents: String
            do {
                contents = try String(
                    contentsOf: fileListPath.url,
                    encoding: .utf8
                )
            } catch {
                throw XCStringsFormatError.fileListReadFailed(
                    path: fileListPath.url.path,
                    detail: error.localizedDescription
                )
            }

            requestedPaths.append(contentsOf: contents.split(whereSeparator: \.isNewline).compactMap {
                let path = String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                return XCStringsFormatInputArgument(argument: path)
            })
        }

        guard !requestedPaths.isEmpty else {
            throw XCStringsFormatError.noInputs
        }

        var inputs: [XCStringsFormatInput] = []
        for requestedPath in requestedPaths {
            switch requestedPath {
            case .standardInput:
                inputs.append(.standardInput)

            case let .file(url):
                let resourceValues: URLResourceValues
                do {
                    resourceValues = try url.resourceValues(
                        forKeys: [.isDirectoryKey]
                    )
                } catch {
                    throw XCStringsFormatError.inputNotFound(path: url.path)
                }

                if resourceValues.isDirectory == true {
                    let directoryFiles = try files(in: url)
                    inputs.append(contentsOf: directoryFiles.map {
                        .file($0)
                    })
                } else {
                    inputs.append(.file(url))
                }
            }
        }

        guard !inputs.isEmpty else {
            throw XCStringsFormatError.noInputs
        }

        return inputs
    }

    private static func files(in directory: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw XCStringsFormatError.directoryReadFailed(path: directory.path)
        }

        var paths: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "xcstrings" else {
                continue
            }

            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                paths.append(url)
            }
        }

        return paths.sorted { $0.path < $1.path }
    }
}
