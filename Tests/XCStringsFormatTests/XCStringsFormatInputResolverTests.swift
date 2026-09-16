import Foundation
import Testing
@testable import XCStringsFormat

struct XCStringsFormatInputResolverTests {
    @Test
    func `rejects an empty input list`() {
        #expect(throws: XCStringsFormatError.self) {
            try XCStringsFormatInputResolver.resolve(
                paths: [],
                fileListPath: nil
            )
        }
    }

    @Test
    func `recursively resolves regular string catalogs in path order`() throws {
        let root = FileManager.default.temporaryDirectory.appending(
            path: "XCStringsFormatTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        let nested = root.appending(path: "Nested", directoryHint: .isDirectory)
        let first = root.appending(path: "01.xcstrings")
        let second = nested.appending(path: "02.xcstrings")
        let nonCatalog = root.appending(path: "notes.txt")

        try FileManager.default.createDirectory(
            at: nested,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        try Data("{}".utf8).write(to: first)
        try Data("{}".utf8).write(to: second)
        try Data("not a catalog".utf8).write(to: nonCatalog)

        let inputs = try XCStringsFormatInputResolver.resolve(
            paths: [.file(root)],
            fileListPath: nil
        )
        let urls = inputs.compactMap { input -> URL? in
            guard case let .file(url) = input else { return nil }
            return url
        }

        #expect(urls.map(\.lastPathComponent) == [
            first.lastPathComponent,
            second.lastPathComponent,
        ])
    }
}
