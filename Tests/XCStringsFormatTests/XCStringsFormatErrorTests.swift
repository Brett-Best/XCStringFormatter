import Testing
@testable import XCStringsFormat

struct XCStringsFormatErrorTests {
    @Test(arguments: [
        (
            XCStringsFormatError.inputNotFound(path: "catalog.xcstrings"),
            "input does not exist: catalog.xcstrings"
        ),
        (
            XCStringsFormatError.fileListReadFailed(
                path: "files.txt",
                detail: "permission denied"
            ),
            "could not read file list files.txt: permission denied"
        ),
        (
            XCStringsFormatError.directoryReadFailed(path: "Catalogs"),
            "could not enumerate directory: Catalogs"
        ),
        (
            XCStringsFormatError.inputReadFailed(
                path: "catalog.xcstrings",
                detail: "read failed"
            ),
            "catalog.xcstrings: could not read input: read failed"
        ),
        (
            XCStringsFormatError.parseFailed(
                path: "catalog.xcstrings",
                detail: "invalid JSON"
            ),
            "catalog.xcstrings: Xcode could not parse the string catalog: invalid JSON"
        ),
        (
            XCStringsFormatError.serializeFailed(
                path: "catalog.xcstrings",
                detail: "invalid catalog"
            ),
            "catalog.xcstrings: Xcode could not serialize the string catalog: invalid catalog"
        ),
        (
            XCStringsFormatError.writeFailed(
                path: "catalog.xcstrings",
                detail: "read-only"
            ),
            "catalog.xcstrings: could not write output: read-only"
        ),
    ])
    func `descriptions include named context`(
        error: XCStringsFormatError,
        expectedDescription: String
    ) {
        #expect(error.description == expectedDescription)
    }
}
