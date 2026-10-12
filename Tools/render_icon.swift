// Draws the "Single Tube" app icon and writes every macOS size into the app's icon set.
//
// Run from the repository root:
//     swift Tools/render_icon.swift
//
// Change the drawing below, run it again, then rebuild the app.
import AppKit
import CoreText
import SwiftUI

let fontURL = URL(fileURLWithPath: "NixieClock/Resources/Fonts/Oswald-Variable.ttf")
let iconSetURL = URL(fileURLWithPath: "NixieClock/Assets.xcassets/AppIcon.appiconset")

guard FileManager.default.fileExists(atPath: fontURL.path),
      FileManager.default.fileExists(atPath: iconSetURL.path) else {
    print("Run this from the repository root: swift Tools/render_icon.swift")
    exit(1)
}
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

extension Color {
    init(_ hex: UInt32, _ alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

let glow = Color(0xFF6A00)

/// Diagonal lines at ±60°, like the tube's anode mesh.
struct Mesh: Shape {
    var spacing: CGFloat = 10
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let len = rect.width + rect.height
        for angle in [60.0, -60.0] {
            let a = angle * .pi / 180
            let dir = CGPoint(x: cos(a), y: sin(a))
            let normal = CGPoint(x: -dir.y, y: dir.x)
            var offset = -len
            while offset < len {
                let c = CGPoint(x: rect.midX + normal.x * offset, y: rect.midY + normal.y * offset)
                path.move(to: CGPoint(x: c.x - dir.x * len, y: c.y - dir.y * len))
                path.addLine(to: CGPoint(x: c.x + dir.x * len, y: c.y + dir.y * len))
                offset += spacing
            }
        }
        return path
    }
}

/// Fine, nearly horizontal wood grain.
struct Grain: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 1
        while y < rect.height + 20 {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y - rect.width * 0.052))
            y += 9
        }
        return path
    }
}

/// A rect whose top corners are `top` round and bottom corners `bottom` round.
func tubeShape(top: CGFloat, bottom: CGFloat) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: bottom,
                           bottomTrailingRadius: bottom, topTrailingRadius: top, style: .continuous)
}

func digit(_ text: String, weight: Font.Weight) -> some View {
    Text(text)
        .font(.custom("Oswald", size: 196).weight(weight))
        .lineLimit(1)
        .fixedSize()
}

/// The icon in the design's 400-point coordinate space.
struct Icon: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RadialGradient(stops: [
                .init(color: Color(0x3A2416), location: 0),
                .init(color: Color(0x1B120C), location: 0.55),
                .init(color: Color(0x0C0806), location: 1),
            ], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 312)

            // Walnut base
            ZStack(alignment: .top) {
                LinearGradient(stops: [
                    .init(color: Color(0x84502C), location: 0),
                    .init(color: Color(0x5A341C), location: 0.6),
                    .init(color: Color(0x3E2312), location: 1),
                ], startPoint: .top, endPoint: .bottom)
                Grain().stroke(Color.black.opacity(0.14), lineWidth: 2)
                Rectangle().fill(Color(0xA8703F)).frame(height: 3)
            }
            .frame(width: 400, height: 82)
            .clipped()
            .offset(y: 318)

            // Glow reflected on the wood
            Ellipse()
                .fill(RadialGradient(colors: [glow.opacity(0.40), glow.opacity(0)],
                                     center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 110))
                .frame(width: 220, height: 70)
                .offset(x: 90, y: 290)

            // Socket
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Color(0x33302D), Color(0x121110)], startPoint: .top, endPoint: .bottom))
                .frame(width: 152, height: 30)
                .offset(x: 124, y: 300)

            // Tube
            ZStack(alignment: .topLeading) {
                tubeShape(top: 82, bottom: 16).fill(Color(0xFFF0E1, 0.05))
                Mesh()
                    .stroke(Color(0xFFD2AA, 0.11), lineWidth: 1)
                    .frame(width: 136, height: 230)
                    .clipShape(tubeShape(top: 64, bottom: 8))
                    .offset(x: 14, y: 26)
                digit("8", weight: .ultraLight)
                    .foregroundStyle(Color(0xFFDCBE, 0.10))
                    .frame(width: 164)
                    .offset(y: 4)
                digit("7", weight: .light)
                    .foregroundStyle(glow)
                    .shadow(color: Color(0xFFF4E6), radius: 1)
                    .shadow(color: glow, radius: 5)
                    .shadow(color: glow, radius: 13)
                    .shadow(color: glow.opacity(0.67), radius: 30)
                    .frame(width: 164)
                    .offset(y: 4)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.white.opacity(0.40), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 12, height: 190)
                    .offset(x: 16, y: 22)
                // Inner glow
                tubeShape(top: 82, bottom: 16)
                    .stroke(glow.opacity(0.25), lineWidth: 24)
                    .blur(radius: 14)
                tubeShape(top: 82, bottom: 16)
                    .stroke(Color(0xFFE1C8, 0.30), lineWidth: 2)
            }
            .frame(width: 164, height: 268)
            .clipShape(tubeShape(top: 82, bottom: 16))
            .background(
                tubeShape(top: 82, bottom: 16)
                    .fill(glow.opacity(0.19))
                    .blur(radius: 24)
            )
            .offset(x: 118, y: 40)
        }
        .frame(width: 400, height: 400, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 90, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

/// Apple's macOS icon grid: an 824-point body centered on a 1024 canvas, with a soft drop shadow.
struct IconCanvas: View {
    var body: some View {
        Icon()
            .scaleEffect(824.0 / 400.0)
            .frame(width: 824, height: 824)
            .shadow(color: .black.opacity(0.30), radius: 12, y: 10)
            .frame(width: 1024, height: 1024)
    }
}

/// Scales the full-size render down to `pixels` square.
func resized(_ image: CGImage, to pixels: Int) -> CGImage {
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try! data.write(to: url)
}

@MainActor func render() {
    let renderer = ImageRenderer(content: IconCanvas())
    renderer.scale = 1
    guard let fullSize = renderer.cgImage else { fatalError("render failed") }

    // The file names Contents.json in the icon set expects.
    for size in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
            let pixels = size * scale
            let image = pixels == fullSize.width ? fullSize : resized(fullSize, to: pixels)
            writePNG(image, to: iconSetURL.appendingPathComponent(name))
            print("wrote \(name) (\(pixels)×\(pixels))")
        }
    }
}

MainActor.assumeIsolated { render() }
