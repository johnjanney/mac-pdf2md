import XCTest
@testable import PDF2MD

final class TitleDetectionTests: XCTestCase {
    private let body = 12.0

    private func line(_ text: String, size: Double) -> TextLine {
        TextLine(text: text, fontSize: size, isBold: false, isItalic: false, isBullet: false)
    }

    func testPrefersFirstHeadingOverMetadata() {
        // The on-page heading wins even when a clean metadata title exists.
        let pages = [[line("On-page Heading", size: 24)]]
        let title = PDFKitConverter.detectTitle(metadata: "Embedded Metadata Title", pages: pages, bodySize: body)
        XCTAssertEqual(title, "On-page Heading")
    }

    func testUsesHeadingWhenMetadataLooksLikeFilename() {
        let pages = [[line("Quarterly Results", size: 20), line("body text", size: 12)]]
        let title = PDFKitConverter.detectTitle(metadata: "Microsoft Word - q3.docx", pages: pages, bodySize: body)
        XCTAssertEqual(title, "Quarterly Results")
    }

    func testFallsBackToMetadataWhenNoHeading() {
        // No heading-sized line on the page → fall back to a clean metadata title.
        let pages = [[line("just body text", size: 12)]]
        let title = PDFKitConverter.detectTitle(metadata: "Embedded Metadata Title", pages: pages, bodySize: body)
        XCTAssertEqual(title, "Embedded Metadata Title")
    }

    func testReturnsNilWhenNoHeadingAndNoUsableMetadata() {
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
