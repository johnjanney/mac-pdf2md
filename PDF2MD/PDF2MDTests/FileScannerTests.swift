import XCTest
@testable import PDF2MD

final class FileScannerTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDF2MDScanner-\(UUID().uuidString)", isDirectory: true)
        let sub = root.appendingPathComponent("nested", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)

        try makeFile("a.pdf")
        try makeFile("b.txt")
        try makeFile("c.PDF")            // case-insensitive extension
        try makeFile("nested/d.pdf")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeFile(_ relativePath: String) throws {
        let url = root.appendingPathComponent(relativePath)
        try "x".write(to: url, atomically: true, encoding: .utf8)
    }

    func testTopLevelFolderScanIgnoresNonPDFAndSubfolders() {
        let scanner = FileScanner(includeSubfolders: false)
        let names = scanner.pdfURLs(from: [root]).map(\.lastPathComponent)
        XCTAssertEqual(names, ["a.pdf", "c.PDF"])
    }

    func testRecursiveScanIncludesSubfolders() {
        let scanner = FileScanner(includeSubfolders: true)
        let names = Set(scanner.pdfURLs(from: [root]).map(\.lastPathComponent))
        XCTAssertEqual(names, ["a.pdf", "c.PDF", "d.pdf"])
    }

    func testDirectFileSelectionIsKept() {
        let file = root.appendingPathComponent("a.pdf")
        let scanner = FileScanner()
        XCTAssertEqual(scanner.pdfURLs(from: [file]).map(\.lastPathComponent), ["a.pdf"])
    }

    func testDeduplicatesOverlappingSelections() {
        let file = root.appendingPathComponent("a.pdf")
        let scanner = FileScanner(includeSubfolders: false)
        // Folder (which contains a.pdf) plus a.pdf directly → a.pdf appears once.
        let names = scanner.pdfURLs(from: [root, file]).map(\.lastPathComponent)
        XCTAssertEqual(names.filter { $0 == "a.pdf" }.count, 1)
    }
}
