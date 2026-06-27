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

    func testJoinsAdjacentSameSizeHeadingLines() {
        // A title split across lines at the same font size is captured whole.
        let pages = [[
            line("Communicating Corporate Social", size: 18),
            line("Responsibility in a Crisis", size: 18),
            line("by Jane Doe", size: 12),
            line("Abstract body text", size: 12),
        ]]
        let title = PDFKitConverter.firstHeading(in: pages, bodySize: body)
        XCTAssertEqual(title, "Communicating Corporate Social Responsibility in a Crisis")
    }

    func testStopsAtSmallerFontAfterHeading() {
        let pages = [[
            line("Main Title", size: 20),
            line("a subtitle in smaller text", size: 13),
            line("Not part of the title", size: 20),
        ]]
        XCTAssertEqual(PDFKitConverter.firstHeading(in: pages, bodySize: body), "Main Title")
    }

    func testStopsAtBlankLineAfterHeading() {
        let pages = [[
            line("First Line", size: 18),
            line("", size: 0),
            line("Second Block", size: 18),
        ]]
        XCTAssertEqual(PDFKitConverter.firstHeading(in: pages, bodySize: body), "First Line")
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
