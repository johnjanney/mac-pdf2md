import XCTest
@testable import PDF2MD

final class TitleDetectionTests: XCTestCase {
    private let body = 12.0

    private func line(_ text: String, size: Double) -> TextLine {
        TextLine(text: text, fontSize: size, isBold: false, isItalic: false, isBullet: false)
    }

    func testPrefersCleanMetadataTitle() {
        let pages = [[line("On-page Heading", size: 24)]]
        let title = PDFKitConverter.detectTitle(metadata: "Annual Report 2025", pages: pages, bodySize: body)
        XCTAssertEqual(title, "Annual Report 2025")
    }

    func testFallsBackToHeadingWhenMetadataLooksLikeFilename() {
        let pages = [[line("Quarterly Results", size: 20), line("body text", size: 12)]]
        let title = PDFKitConverter.detectTitle(metadata: "Microsoft Word - q3.docx", pages: pages, bodySize: body)
        XCTAssertEqual(title, "Quarterly Results")
    }

    func testFallsBackToHeadingWhenMetadataMissing() {
        let pages = [[line("My Document Title", size: 18), line("intro", size: 12)]]
        let title = PDFKitConverter.detectTitle(metadata: nil, pages: pages, bodySize: body)
        XCTAssertEqual(title, "My Document Title")
    }

    func testReturnsNilWhenNothingUsable() {
        let pages = [[line("just body text", size: 12)]]
        let title = PDFKitConverter.detectTitle(metadata: "  ", pages: pages, bodySize: body)
        XCTAssertNil(title)
    }

    func testIgnoresOverlongHeadingAsTitle() {
        let longHeading = String(repeating: "word ", count: 40) // > 120 chars
        let pages = [[line(longHeading, size: 24)]]
        XCTAssertNil(PDFKitConverter.firstHeading(in: pages, bodySize: body))
    }

    func testCleanTitleCollapsesWhitespace() {
        XCTAssertEqual(PDFKitConverter.cleanTitle("  A   spaced\n title "), "A spaced title")
        XCTAssertNil(PDFKitConverter.cleanTitle("   "))
    }

    func testIsLikelyFilename() {
        XCTAssertTrue(PDFKitConverter.isLikelyFilename("report.pdf"))
        XCTAssertTrue(PDFKitConverter.isLikelyFilename("Microsoft Word - draft.docx"))
        XCTAssertFalse(PDFKitConverter.isLikelyFilename("A Real Title"))
    }
}
