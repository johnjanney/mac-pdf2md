import Foundation
import PDFKit
import AppKit

/// Renders PDF pages to PNG image data for the vision-based LLM engine.
///
/// Preserving tables, charts, and visual layout requires the model to *see*
/// the page, so each page is rasterized to an image and sent to the provider.
struct PageRenderer: Sendable {
    /// Longest edge of the rendered image, in pixels. Large enough for the
    /// model to read small text, capped to keep request size/cost reasonable.
    var maxDimension: CGFloat = 2000

    /// Render a single page to base64-encoded PNG data, or nil on failure.
    func renderPNGBase64(page: PDFPage) -> String? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 1, bounds.height > 1 else { return nil }

        let scale = min(maxDimension / max(bounds.width, bounds.height), 3.0)
        let pixelsWide = Int((bounds.width * scale).rounded())
        let pixelsHigh = Int((bounds.height * scale).rounded())
        guard pixelsWide > 0, pixelsHigh > 0,
              let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: pixelsWide, pixelsHigh: pixelsHigh,
                                         bitsPerSample: 8, samplesPerPixel: 4,
                                         hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
            return nil
        }
        rep.size = NSSize(width: pixelsWide, height: pixelsHigh)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        let cg = ctx.cgContext
        // White background (PDF pages are transparent by default).
        cg.setFillColor(NSColor.white.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh))
        cg.scaleBy(x: scale, y: scale)
        cg.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        page.draw(with: .mediaBox, to: cg)
        ctx.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])?.base64EncodedString()
    }
}
