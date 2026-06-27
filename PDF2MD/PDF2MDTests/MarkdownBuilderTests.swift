import XCTest
@testable import PDF2MD

final class MarkdownBuilderTests: XCTestCase {
    private let body = 12.0

    private func line(_ text: String, size: Double = 12, bullet: Bool = false) -> TextLine {
        TextLine(text: text, fontSize: size, isBold: false, isItalic: false, isBullet: bullet)
    }

    func testPromotesLargeShortLineToHeading() {
        var b = MarkdownBuilder()
        b.add(line: line("Title", size: 24), bodySize: body)         // 2.0x → #
        b.add(line: line("Section", size: 16), bodySize: body)       // 1.33x → ###
        b.add(line: line("Body text here.", size: 12), bodySize: body)
        let md = b.build()
        XCTAssertTrue(md.contains("# Title"))
        XCTAssertTrue(md.contains("### Section"))
        XCTAssertTrue(md.contains("Body text here."))
    }

    func testJoinsWrappedParagraphLines() {
        var b = MarkdownBuilder()
        b.add(line: line("This is one"), bodySize: body)
        b.add(line: line("paragraph split"), bodySize: body)
        b.add(line: line("across lines."), bodySize: body)
        XCTAssertEqual(b.build(), "This is one paragraph split across lines.\n")
    }

    func testGroupsConsecutiveBulletsIntoTightList() {
        var b = MarkdownBuilder()
        b.add(line: line("• First", bullet: true), bodySize: body)
        b.add(line: line("• Second", bullet: true), bodySize: body)
        let md = b.build()
        XCTAssertEqual(md, "- First\n- Second\n")
    }

    func testParagraphAndListAreSeparatedByBlankLine() {
        var b = MarkdownBuilder()
        b.add(line: line("Intro."), bodySize: body)
        b.add(line: line("- item", bullet: true), bodySize: body)
        let md = b.build()
        XCTAssertEqual(md, "Intro.\n\n- item\n")
    }

    func testStripsNumberedMarker() {
        XCTAssertEqual(MarkdownBuilder.stripBulletMarker(from: "1. Hello"), "Hello")
        XCTAssertEqual(MarkdownBuilder.stripBulletMarker(from: "2) World"), "World")
        XCTAssertEqual(MarkdownBuilder.stripBulletMarker(from: "• Glyph"), "Glyph")
    }

    func testLongLineIsNotAHeadingEvenWhenLarge() {
        let longText = String(repeating: "word ", count: 40) // > 120 chars
        var b = MarkdownBuilder()
        b.add(line: line(longText, size: 30), bodySize: body)
        XCTAssertFalse(b.build().hasPrefix("#"))
    }
}
