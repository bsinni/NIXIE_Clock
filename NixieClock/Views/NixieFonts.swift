import CoreText
import SwiftUI

/// The bundled fonts: Oswald for the tube numerals and Cinzel for the nameplate.
/// Both are under the SIL Open Font License 1.1; the licenses ship in Resources/Fonts.
enum NixieFonts {
    /// Registers the bundled fonts for this process. Safe to call more than once.
    static func register() {
        _ = registration
    }

    private static let registration: Void = {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// Tall, condensed numerals in Oswald Light. Falls back to the system font if
    /// the bundled font is missing.
    static func numeral(size: CGFloat) -> Font {
        register()
        return .custom("Oswald", size: size).weight(.light)
    }

    /// Engraved-plate lettering in Cinzel SemiBold.
    static func nameplate(size: CGFloat) -> Font {
        register()
        return .custom("Cinzel", size: size).weight(.semibold)
    }
}
