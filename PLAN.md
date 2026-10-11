# Nixie Desk Clock — Build Plan

A native macOS desktop app (Swift + SwiftUI) that shows one or more Nixie tube clocks sitting on the
desktop: glass tubes on a wooden base, large glowing digits in any color, HH:MM:SS, any time zone,
freely resizable.

Visual design (live, tweakable mockup): https://claude.ai/artifact/G9wEHni1ytn3sddhnEzndf

## Target and tooling

- macOS 14 Sonoma or later (for `MenuBarExtra`, `TimelineView`, modern SwiftUI APIs)
- Xcode 27, Swift 6, SwiftUI with small AppKit bridges for window behavior
- Signed with a free Apple ID (Personal Team); no paid developer account needed to run it locally
- No third-party dependencies

## How it behaves

- **Lives on the desktop.** Each clock is a borderless, transparent `NSWindow` at desktop level,
  so app windows cover it. It appears on every Space and is hidden from the Dock and Cmd-Tab
  (`LSUIElement = YES`).
- **Menu bar item** (`MenuBarExtra`, window style) holds all settings, the clock list, and Quit.
- **Several clocks.** Add a clock with +. Each has its own window, time zone, color, and options.
- **Resize** by dragging any window edge. The tubes scale proportionally (aspect ratio locked).
  A Size slider does the same thing.
- **Move** by dragging the clock. **Lock position** makes it click-through so it behaves like a
  wallpaper element.
- **Launch at login** via `SMAppService.mainApp`.

## Appearance (matches the mockup)

Each **tube**, back to front:
1. Exhaust tip: a small glass nub on top of the dome.
2. Glass envelope: a capsule with a domed top, a horizontal gradient (bright edges, clear middle),
   a thin light stroke, and an inner shadow toward the bottom.
3. Ambient tint: a soft radial wash of the glow color inside the glass.
4. Ghost digits: all ten numerals stacked at ~9% opacity in a dull copper, so the unlit cathodes show.
5. Lit digit: a large, thin, condensed numeral in a lightened version of the glow color.
6. Glow: stacked `.shadow` passes (about 2, 6, 18 and 42 pt) in the glow color plus a hot core.
7. Anode mesh: a fine diamond grid drawn with `Canvas` at low opacity over the digit.
8. Highlights: a long vertical reflection streak on the left and a thin one on the right.
9. Socket: a dark metal cup with a brass ring where the glass meets it.

**Separators**: two small neon bulbs (INS-1 style) between groups that blink once per second
(optional).

**Wooden base**: a plinth under the tubes with a lighter top bevel, a routed edge line, horizontal
grain (layered gradients plus subtle noise), a deep drop shadow, and a reflection of the glow on
the top surface. Finishes: Walnut (default), Oak, Ebony. A **brass nameplate** with two screws shows
the city, GMT offset, and AM/PM in 12-hour mode.

**Background**: a rounded panel behind the tubes and base, in any color. *Vignette* draws a soft
radial gradient (slightly lighter in the middle, darker at the edges) from the chosen color, *Solid*
fills it flat, and *Transparent* removes the panel so the clock floats directly on the wallpaper.
Drawn by `BackgroundPanelView`; the window itself stays clear so rounded corners and transparency work.

**Font**: a thin condensed face for the numerals. Bundle an open-license font (for example
Oswald Light, under the SIL Open Font License) and fall back to `.system(weight: .ultraLight)` with
`scaleEffect(x: 0.85)`. Cinzel (OFL) for the nameplate.

## Settings (per clock)

| Setting | Control | Default |
|---|---|---|
| Time zone | Searchable list of `TimeZone.knownTimeZoneIdentifiers`, shown as "Tokyo — Asia/Tokyo · GMT+9" | System zone |
| Glow color | 6 preset swatches + **Custom…** (SwiftUI `ColorPicker`, any color) | Nixie orange `#FF6A00` |
| Background color | 5 preset swatches + **Custom…** (`ColorPicker`, any color, with opacity) | Near-black `#0C0B0B` |
| Background style | Segmented: Vignette / Solid / Transparent | Vignette |
| 24-hour time | Toggle | On |
| Show seconds | Toggle | On |
| Blink separators | Toggle | On |
| Show city plate | Toggle | On |
| Wood finish | Segmented: Walnut / Oak / Ebony | Walnut |
| Size | Slider (50–200%), also window-edge drag | 100% |
| Lock position | Toggle (click-through) | Off |
| Launch at login | Toggle (app-wide) | On |

## Architecture

```
NixieClock/
  NixieClockApp.swift        @main; MenuBarExtra + clock window management
  Model/
    ClockConfig.swift        Codable: id, timeZoneID, colorHex, backgroundHex, backgroundStyle,
                             use24h, showSeconds,
                             blinkSeparators, showPlate, wood, scale, frame, locked
    ClockStore.swift         @Observable; [ClockConfig], saved as JSON in UserDefaults
    TimeZoneCatalog.swift    searchable zone list, display names, GMT offsets
  Windows/
    DesktopWindow.swift      NSWindow subclass: borderless, clear, desktop level,
                             canJoinAllSpaces + stationary, aspect-locked resize
    ClockWindowController.swift  one per clock; hosts NixieClockView, saves frame
  Views/
    NixieClockView.swift     TimelineView(.periodic(by: 1)) → tubes + separators + base
    NixieTubeView.swift      the layered tube described above
    SeparatorLampView.swift  neon bulb pair
    WoodBaseView.swift       plinth, grain, bevel, glow reflection, nameplate
    BackgroundPanelView.swift  vignette / solid / transparent panel in the chosen color
    MeshPattern.swift        Canvas-drawn anode grid
  Settings/
    MenuPanelView.swift      clock list + settings for the selected clock
    TimeZonePicker.swift     search field + filtered results
  Resources/
    Fonts/ (Oswald-Light.ttf, Cinzel-SemiBold.ttf + OFL license files)
    Info.plist               LSUIElement = YES, ATSApplicationFontsPath
```

Time formatting: a `Calendar` whose `timeZone` is the clock's zone gives hour, minute, and second
for the current `Date`. Digits come from those components, never from a locale string, so the tube
count is always fixed.

## Phases

1. **Project skeleton**: create the macOS app project, set `LSUIElement`, add a `MenuBarExtra` with
   Quit, and open one borderless desktop-level window showing plain "12:34:56". Confirms signing and
   window behavior.
2. **Tube rendering**: build `NixieTubeView` layer by layer with an Xcode `#Preview` showing several
   colors side by side. Most of the design time goes here.
3. **Clock layout and base**: tubes, separator lamps, wooden base with the three finishes, nameplate;
   driven by `TimelineView` once per second. Scale the whole view from one base size so every size
   looks the same.
4. **Window behavior**: desktop level, all Spaces, drag to move, aspect-locked edge resize, lock /
   click-through, remember each window's frame.
5. **Settings and multiple clocks**: `ClockStore` persistence, menu panel, searchable time zone
   picker, glow and background swatches + `ColorPicker`s, background style, per-clock toggles,
   add and remove clocks.
6. **Polish**:
   - digit change: a short crossfade (about 120 ms) with a brief glow flare, like a real tube striking
   - optional "cathode cycle" once an hour (each tube runs through 0–9) as nixie clocks do
   - launch at login; sensible default placement for new clocks
   - check DST changes and half/quarter-hour zones (India GMT+5:30, Nepal GMT+5:45)
   - CPU check: one redraw per second should stay well under 1%. If not, cache the static
     glass/base layers with `drawingGroup()` and redraw only the digits.
7. **Optional later**: a screen saver using the same views, or a WidgetKit widget (HH:MM only)
   sharing `NixieTubeView`.
