# Nixie Desk Clock — Build Plan

A native macOS desktop app (Swift + SwiftUI) that shows one or more Nixie tube clocks sitting on the
desktop: glass tubes on a wooden base, large glowing digits in any color, HH:MM:SS, any time zone,
freely resizable.

Visual design (live, tweakable mockup): https://claude.ai/artifact/G9wEHni1ytn3sddhnEzndf

**Status:** Phases 1–6 are built. Phase 7 is optional future work. Where the build differs from
the original plan, this file describes what was built and says why.

## Target and tooling

- macOS 14 Sonoma or later (for `MenuBarExtra`, `TimelineView`, `KeyframeAnimator`, modern SwiftUI APIs)
- Xcode 27, Swift 6 (default actor isolation: MainActor), SwiftUI with small AppKit bridges for
  window behavior
- Signed to run locally; a free Apple ID (Personal Team) can be chosen in Xcode. No paid developer
  account is needed to run it on your own Mac.
- No third-party code dependencies. Two bundled open-license fonts (see Fonts).

## How it behaves

- **Lives on the desktop.** Each clock is a borderless, transparent `NSWindow` just above the
  desktop icons, so app windows cover it. It appears on every Space and is hidden from the Dock and
  Cmd-Tab (`LSUIElement = YES`).
- **Menu bar item** (`MenuBarExtra`, window style) holds the clock list, all settings, and Quit.
- **Several clocks.** Add a clock with **+**. Each has its own window, time zone, colors, and options.
  New clocks open slightly offset so they don't stack exactly on top of each other.
- **Resize** by dragging any edge or corner. The clock keeps its shape (aspect ratio locked) and
  scales as one unit. The Size slider does the same around the window's center.
- **Move** by dragging anywhere on the clock. It works on the first click, even when the app isn't
  active. **Lock position** makes the clock click-through so it behaves like part of the wallpaper.
  With a Transparent background, clicks on fully clear areas between tubes always pass through
  (macOS behavior), so grab a tube or the base to move it.
- **Remembers** every clock's settings, position, and size between launches. A clock saved on a
  display that's no longer connected reopens centered on the main screen.
- **Launch at login** via `SMAppService.mainApp`. Off by default (see Settings).

## Appearance (matches the mockup)

Each **tube** is laid out on a 112 × 310 design grid and scaled, so it's sharp at any size.
Back to front:
1. Exhaust tip: a small glass nub on top of the dome.
2. Glass envelope: a domed capsule with a horizontal gradient (bright edges, clear middle), a thin
   light edge, and darkening toward the socket.
3. Ambient tint: a soft radial wash of the glow color inside the glass.
4. Ghost digits: all ten numerals stacked at ~9% opacity in a dull copper, so the unlit cathodes show.
5. Lit digit: a large Oswald Light numeral in a lightened "hot core" version of the glow color.
6. Glow: three blurred copies of the numeral (radius about 2.5, 8, and 20) in the glow color.
7. Anode mesh: a fine diamond grid drawn with `Canvas` at low opacity, in front of the digit.
8. Highlights: a long vertical reflection streak on the left and a thin one on the right.
9. Socket: a dark metal cup with a brass ring where the glass meets it.

**Separators**: two small neon bulbs (INS-1 style) between digit pairs that blink once per second
(optional).

**Wooden base**: a plinth under the tubes with a light top edge, a routed groove, wavy horizontal
grain with a couple of darker knots, a deep drop shadow, and the glow reflected on the top surface.
Finishes: Walnut (default), Oak, Ebony. A **brass nameplate** with two screws shows the city, GMT
offset, and AM/PM in 12-hour mode.

**Background**: a rounded panel behind the tubes and base, in any color and opacity. *Vignette* draws
a soft radial gradient (slightly lighter in the middle, darker at the edges) from the chosen color,
*Solid* fills it flat, and *Transparent* removes the panel so the clock floats on the wallpaper.
The window itself stays clear so rounded corners and transparency work.

**Motion**:
- Digit changes crossfade over about 0.12 s (optional, see Performance).
- Hourly cathode cycle: at the top of each hour, every tube runs through all ten digits for
  2 seconds, offset tube to tube so the row ripples, as real nixie clocks do to keep unused
  cathodes from wearing out. It follows each clock's own time zone, so a Kolkata clock cycles at
  :30 past the hour UTC. The clock ticks ten times a second only while the cycle runs, and skips the
  fast frames in low-power mode.

## Fonts

Both are bundled in `NixieClock/Resources/Fonts/` with their license files, downloaded from the
Google Fonts repository (`github.com/google/fonts`, `ofl/` folder). Both use the SIL Open Font
License 1.1, which allows bundling them in an app.

| Font | Used for | File | Weight used |
|---|---|---|---|
| Oswald (variable, weights 200–700) | Tube numerals | `Oswald-Variable.ttf` | Light (300) |
| Cinzel (variable, weights 400–900) | Nameplate | `Cinzel-Variable.ttf` | SemiBold (600) |

`NixieFonts` registers them for the app at launch with `CTFontManagerRegisterFontsForURL`.
`GENERATE_INFOPLIST_FILE` doesn't support `ATSApplicationFontsPath`, so they aren't listed in
Info.plist. If a font is missing, SwiftUI falls back to the system font.

## Settings

Per clock unless noted.

| Setting | Control | Default |
|---|---|---|
| Time zone | Search by city, zone ID, or long name ("Japan Standard Time"); results show city, zone ID, and GMT offset. "Local time" follows the system. | Local time |
| Glow color | 6 preset swatches + **Custom…** (system color panel, any color) | Nixie Orange `#FF6A00` |
| Background color | 5 preset swatches + **Custom…** (system color panel, any color and opacity) | Near-black `#0C0B0B` |
| Background style | Segmented: Vignette / Solid / Transparent | Vignette |
| 24-hour time | Switch | On |
| Show seconds | Switch (turning it off shows four tubes and narrows the window) | On |
| Blink separators | Switch | On |
| Show city plate | Switch | On |
| Animate digit changes | Switch | On |
| Hourly digit cycle | Switch | On |
| Wood finish | Segmented: Walnut / Oak / Ebony | Walnut |
| Size | Slider 50–200% of default, plus **Reset Size and Position**; also window-edge drag | 100% |
| Lock position | Switch (click-through) | Off |
| Launch at login | Switch (app-wide). Shows a link to Login Items if macOS needs approval. | **Off** |

Launch at login defaults to off, not on as first planned. The app currently runs from the Xcode
build folder, and registering a login item that points there would be fragile and surprising.
Turn it on once the app lives in /Applications.

The **Custom…** color buttons drive the system color panel through a long-lived object
(`ColorPanelCoordinator`) rather than SwiftUI's `ColorPicker`. The menu bar panel closes as soon as
the color panel takes focus, and a `ColorPicker` inside it would stop applying changes.

## Architecture

```
NixieClock/
  NixieClockApp.swift          @main; MenuBarExtra (window style) + AppDelegate
  Model/
    ClockConfig.swift          Codable settings for one clock; decodes field by field with
                               defaults so older saved settings keep loading
    ClockStore.swift           @Observable list of clocks, saved as JSON in UserDefaults
    TimeZoneCatalog.swift      searchable zones, city names, "GMT+5:30"-style offsets
    NixieColor.swift           preset colors, hex parsing/formatting, NixieGlow (glow + hot core)
    LaunchAtLogin.swift        SMAppService wrapper
  Windows/
    DesktopWindow.swift        borderless, clear NSWindow above desktop icons, all Spaces
    ClockHostingView.swift     NSHostingView subclass: drag to move, aspect-locked edge/corner
                               resize with resize cursors; ClockWindowContent (SwiftUI root)
    ClockWindowController.swift  one per clock: placement, lock, aspect, size, debounced frame saving
    ClockManager.swift         keeps one window per clock; all setting changes go through it
  Views/
    NixieClockView.swift       TimelineView(ClockSchedule) → ClockFaceView; ClockLayout (design
                               grid); ClockTime (digits, nameplate text, cathode cycle)
    NixieTubeView.swift        the layered tube; LitDigitCache (pre-rendered glowing digits)
    SeparatorLampView.swift    neon bulb
    WoodBaseView.swift         plinth, grain, glow reflection, brass nameplate
    BackgroundPanelView.swift  vignette / solid / transparent panel
    MeshPattern.swift          Canvas-drawn anode mesh
    DesignGrid.swift           .placed(_:scale:) helper for design-unit layout
    NixieFonts.swift           registers and vends the bundled fonts
  Settings/
    MenuPanelView.swift        clock list, per-clock settings, launch at login, Remove, Quit
    ColorPanelCoordinator.swift  system color panel for the Custom… buttons
  Resources/
    Fonts/                     Oswald-Variable.ttf, Cinzel-Variable.ttf, *-OFL.txt
```

The Xcode project uses folder-synchronized groups, so new files under `NixieClock/` are picked up
without editing the project file.

Time formatting: a `Calendar` whose `timeZone` is the clock's zone gives hour, minute, and second
for the current `Date`. Digits come from those components, never from a locale string, so the tube
count is always fixed.

## Performance

Measured with one clock in a Release build:

| Configuration | CPU |
|---|---|
| No digit animation | ~0.5% |
| Crossfade (shipped) | ~1.5% |
| Crossfade + glow flare (dropped) | ~4–5% |

Profiling showed the cost is SwiftUI and Core Animation re-rendering the window on each animation
frame, not drawing the blurs. What helped:
- Each glowing digit is pre-rendered once into an image (`LitDigitCache`, keyed by digit, color,
  and size), so a digit change only fades images.
- The tube's static back and front layers are flattened with `drawingGroup()`.

Together these took the crossfade from ~2.5% to ~1.5%. The original target of "well under 1%" holds
only with **Animate digit changes** off. Each additional animated clock adds roughly 1%.

## Phases

1. ✅ **Project skeleton**: macOS app project, `LSUIElement`, `MenuBarExtra` with Quit, and one
   borderless desktop-level window.
2. ✅ **Tube rendering**: `NixieTubeView` layer by layer, with Xcode previews of all colors and digits.
3. ✅ **Clock layout and base**: tubes, separator lamps, wooden base in three finishes, nameplate,
   background panel; the whole clock scales from one design grid.
4. ✅ **Window behavior**: drag to move, aspect-locked edge/corner resize, lock/click-through,
   saved frames.
5. ✅ **Settings and multiple clocks**: `ClockStore` persistence, menu panel, searchable time zones,
   glow and background colors, background style, per-clock switches, add and remove clocks.
6. ✅ **Polish**:
   - digit crossfade (~0.12 s), optional per clock
   - hourly cathode cycle, optional per clock
   - launch at login (off by default)
   - bundled Oswald and Cinzel fonts
   - checked DST changes (New York spring and fall, London, Sydney), half/quarter-hour zones
     (Kolkata +5:30, Kathmandu +5:45, Newfoundland −2:30, Chatham +13:45), 12-hour midnight/noon,
     and the cycle timing
   - CPU measured and reduced (see Performance)
   - **Changed from plan:** the brief glow flare on digit changes was dropped, because it roughly
     tripled CPU use for a small visual effect.
7. **Optional later**:
   - a screen saver using the same views
   - a WidgetKit widget (HH:MM only) sharing `NixieTubeView`
   - unit tests for `ClockTime`, `ClockSchedule`, and `TimeZoneCatalog`; the Phase 6 checks were run
     as a one-off script, and the project has no test target yet
   - install to /Applications and turn on launch at login
