// Renders the README screenshots from the app's own clock views into docs/images.
//
// Run from the repository root:
//     swiftc -default-isolation MainActor -swift-version 5 -O -o /tmp/render_readme_images \
//         -parse-as-library Tools/render_readme_images.swift NixieClock/Model/*.swift NixieClock/Views/*.swift
//     /tmp/render_readme_images
//
// Each shot uses a fixed time so the images don't change between runs.
import AppKit
import CoreText
import SwiftUI

struct Shot {
    var file: String
    /// Wall-clock time in the shot's time zone.
    var time: String
    /// Draws a desktop-like gradient behind the clock, for the Transparent style.
    var wallpaper = false
    var configure: (inout ClockConfig) -> Void
}

@main
enum RenderReadmeImages {
    static func main() throws {
        let fontsURL = URL(fileURLWithPath: "NixieClock/Resources/Fonts")
        let outputURL = URL(fileURLWithPath: "docs/images")

        guard FileManager.default.fileExists(atPath: fontsURL.path) else {
            print("Run this from the repository root (see the comment at the top of the file).")
            exit(1)
        }
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        for name in ["Oswald-Variable.ttf", "Cinzel-Variable.ttf"] {
            CTFontManagerRegisterFontsForURL(fontsURL.appendingPathComponent(name) as CFURL, .process, nil)
        }

        let shots: [Shot] = [
            Shot(file: "hero", time: "2026-10-20T10:08:36") { c in
                c.timeZoneID = "America/New_York"
            },
            Shot(file: "ice-blue-ebony", time: "2026-10-20T23:47:12") { c in
                c.timeZoneID = "Asia/Tokyo"; c.colorHex = "#3DA9FF"; c.wood = .ebony
            },
            Shot(file: "green-oak", time: "2026-10-20T19:25:50") { c in
                c.timeZoneID = "Europe/London"; c.colorHex = "#39FF88"; c.wood = .oak; c.backgroundStyle = .solid
            },
            Shot(file: "violet-12h", time: "2026-10-20T15:42:00") { c in
                c.timeZoneID = "Asia/Kolkata"; c.colorHex = "#B266FF"; c.use24h = false; c.showSeconds = false
            },
            Shot(file: "red-transparent", time: "2026-10-20T07:19:33", wallpaper: true) { c in
                c.timeZoneID = "Australia/Sydney"; c.colorHex = "#FF2D55"; c.backgroundStyle = .transparent
            },
        ]

        let wallpaper = LinearGradient(
            colors: [Color(hex: "#1B2A4A")!, Color(hex: "#3B2357")!, Color(hex: "#6B3A4F")!],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        for shot in shots {
            var config = ClockConfig()
            config.cathodeCycle = false
            config.animateDigits = false
            shot.configure(&config)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = config.timeZone
            let date = formatter.date(from: shot.time)!

            let size = ClockLayout(showSeconds: config.showSeconds).size
            let face = ClockFaceView(config: config, date: date, s: 1)
                .frame(width: size.width, height: size.height)
            let view = ZStack {
                if shot.wallpaper {
                    RoundedRectangle(cornerRadius: 28).fill(wallpaper)
                }
                face
            }
            .frame(width: size.width, height: size.height)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            renderer.isOpaque = false
            guard let image = renderer.cgImage,
                  let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                print("Couldn't render \(shot.file)")
                continue
            }
            try png.write(to: outputURL.appendingPathComponent("\(shot.file).png"))
            print("Wrote docs/images/\(shot.file).png (\(image.width) × \(image.height))")
        }
    }
}
