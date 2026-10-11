import AppKit
import SwiftUI

/// Hosts a clock and handles the mouse for its borderless window:
/// drag anywhere to move, drag an edge or corner to resize with the aspect ratio kept.
final class ClockHostingView: NSHostingView<ClockWindowContent> {
    /// How far in from the window edge a press starts a resize.
    static let edgeThickness: CGFloat = 12
    static let minimumWidth: CGFloat = 220

    /// Which edges a resize moves: -1 = left/bottom, 1 = right/top, 0 = neither.
    /// Uses window coordinates, where y grows upward.
    private struct Edge {
        var x: CGFloat
        var y: CGFloat
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // The clock has no clickable controls, so take every click here instead of
    // letting SwiftUI's internal views claim it; that keeps move and resize working.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if let edge = edge(at: event.locationInWindow) {
            trackResize(from: edge, in: window)
        } else {
            window.performDrag(with: event)
        }
    }

    private func edge(at point: NSPoint) -> Edge? {
        let t = Self.edgeThickness
        let x: CGFloat = point.x < t ? -1 : point.x > bounds.width - t ? 1 : 0
        let y: CGFloat = point.y < t ? -1 : point.y > bounds.height - t ? 1 : 0
        return x == 0 && y == 0 ? nil : Edge(x: x, y: y)
    }

    /// Runs until the mouse is released, resizing around the opposite edge or corner.
    private func trackResize(from edge: Edge, in window: NSWindow) {
        let start = window.frame
        let startMouse = NSEvent.mouseLocation
        let aspect = start.width / start.height
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? start
        let maxWidth = max(Self.minimumWidth, min(visible.width, visible.height * aspect))

        while let event = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]),
              event.type == .leftMouseDragged {
            let mouse = NSEvent.mouseLocation
            let widthFromX = start.width + edge.x * (mouse.x - startMouse.x)
            let widthFromY = (start.height + edge.y * (mouse.y - startMouse.y)) * aspect

            var width: CGFloat
            if edge.y == 0 {
                width = widthFromX
            } else if edge.x == 0 {
                width = widthFromY
            } else {
                // Corner: follow whichever direction the mouse moved further.
                width = abs(widthFromX - start.width) >= abs(widthFromY - start.width) ? widthFromX : widthFromY
            }
            width = min(max(width, Self.minimumWidth), maxWidth)
            let height = width / aspect

            let x = edge.x < 0 ? start.maxX - width : edge.x > 0 ? start.minX : start.midX - width / 2
            let y = edge.y < 0 ? start.maxY - height : edge.y > 0 ? start.minY : start.midY - height / 2
            window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let w = bounds.width
        let h = bounds.height
        let t = Self.edgeThickness
        guard w > 2 * t, h > 2 * t else { return }

        // Rects in window coordinates (y up), converted for this view.
        func add(_ rect: NSRect, _ cursor: NSCursor) {
            addCursorRect(convert(rect, from: nil), cursor: cursor)
        }
        add(NSRect(x: 0, y: t, width: t, height: h - 2 * t), cursor(.left))
        add(NSRect(x: w - t, y: t, width: t, height: h - 2 * t), cursor(.right))
        add(NSRect(x: t, y: 0, width: w - 2 * t, height: t), cursor(.bottom))
        add(NSRect(x: t, y: h - t, width: w - 2 * t, height: t), cursor(.top))
        add(NSRect(x: 0, y: 0, width: t, height: t), cursor(.bottomLeft))
        add(NSRect(x: w - t, y: 0, width: t, height: t), cursor(.bottomRight))
        add(NSRect(x: 0, y: h - t, width: t, height: t), cursor(.topLeft))
        add(NSRect(x: w - t, y: h - t, width: t, height: t), cursor(.topRight))
    }

    private enum CursorEdge {
        case left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight
    }

    private func cursor(_ edge: CursorEdge) -> NSCursor {
        if #available(macOS 15.0, *) {
            let position: NSCursor.FrameResizePosition = switch edge {
            case .left: .left
            case .right: .right
            case .top: .top
            case .bottom: .bottom
            case .topLeft: .topLeft
            case .topRight: .topRight
            case .bottomLeft: .bottomLeft
            case .bottomRight: .bottomRight
            }
            return .frameResize(position: position, directions: .all)
        }
        switch edge {
        case .left, .right: return .resizeLeftRight
        case .top, .bottom: return .resizeUpDown
        default: return .crosshair
        }
    }
}

/// The SwiftUI root of a clock window. Reads its settings from the store so
/// changes show up immediately.
struct ClockWindowContent: View {
    let store: ClockStore
    let id: UUID

    var body: some View {
        if let config = store.clock(id) {
            NixieClockView(config: config)
        }
    }
}
