import Foundation
import Testing
@testable import XCStringsFormat

enum XCStringsFormatterInput: Sendable {
    case data
    case file
}

struct XCStringsFormatterTests {
    @Test(arguments: [XCStringsFormatterInput.data, .file])
    func `formats a catalog through Xcode serialization`(
        input: XCStringsFormatterInput
    ) throws {
        let inputData = Data(
            #"{"version":"1.0","strings":{"z":{"localizations":{"fr":{"stringUnit":{"value":"Zed","state":"translated"}}},"comment":"z comment"},"a":{"comment":"a comment"}},"sourceLanguage":"en"}"#.utf8
        )
        let formatter = XCStringsFormatter()
        let result: XCStringsFormatResult

        switch input {
        case .data:
            result = try formatter.formatData(inputData, source: "test")

        case .file:
            let directory = FileManager.default.temporaryDirectory.appending(
                path: "XCStringsFormatter-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
            let source = directory.appending(path: "Localizable.xcstrings")
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            defer { try? FileManager.default.removeItem(at: directory) }
            try inputData.write(to: source)

            result = try formatter.formatFile(at: source)
        }

        #expect(result.input == inputData)
        #expect(result.changed)
        #expect(
            String(decoding: result.output, as: UTF8.self).contains(
                #""sourceLanguage" : "en""#
            )
        )
        #expect(
            String(decoding: result.output, as: UTF8.self).contains(
                #""strings" : {"#
            )
        )
    }

    @Test
    func `captures parser errors from Xcode serialization`() {
        #expect(throws: XCStringsFormatError.self) {
            try XCStringsFormatter().formatData(
                Data("not a string catalog".utf8),
                source: "test"
            )
        }
    }
}
