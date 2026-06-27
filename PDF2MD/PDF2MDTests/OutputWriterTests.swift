import XCTest
@testable import PDF2MD

final class OutputWriterTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDF2MDTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testWritesExpectedFileName() throws {
        let writer = OutputWriter(folder: tempDir)
        let url = try writer.write(MarkdownDocument(markdown: "# Hi\n", pageCount: 1), sourceName: "report")
        XCTAssertEqual(url.lastPathComponent, "report.md")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Hi\n")
    }

    func testCollisionAppendsNumericSuffix() throws {
        let writer = OutputWriter(folder: tempDir)
        let first = try writer.write(MarkdownDocument(markdown: "a", pageCount: 1), sourceName: "doc")
        let second = try writer.write(MarkdownDocument(markdown: "b", pageCount: 1), sourceName: "doc")
        let third = try writer.write(MarkdownDocument(markdown: "c", pageCount: 1), sourceName: "doc")

        XCTAssertEqual(first.lastPathComponent, "doc.md")
        XCTAssertEqual(second.lastPathComponent, "doc-1.md")
        XCTAssertEqual(third.lastPathComponent, "doc-2.md")
    }

    func testRespectsExistingFilesOnDisk() throws {
        try "existing".write(to: tempDir.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
        let writer = OutputWriter(folder: tempDir)
        let url = try writer.write(MarkdownDocument(markdown: "new", pageCount: 1), sourceName: "notes")
        XCTAssertEqual(url.lastPathComponent, "notes-1.md")
    }

    func testOverwriteModeReusesName() throws {
        let writer = OutputWriter(folder: tempDir, overwrite: true)
        let first = try writer.write(MarkdownDocument(markdown: "a", pageCount: 1), sourceName: "x")
        let second = try writer.write(MarkdownDocument(markdown: "b", pageCount: 1), sourceName: "x")
        XCTAssertEqual(first.lastPathComponent, "x.md")
        XCTAssertEqual(second.lastPathComponent, "x.md")
        XCTAssertEqual(try String(contentsOf: second, encoding: .utf8), "b")
    }
}
