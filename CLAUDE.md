# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Orbit ("Orbit") is a native SwiftUI focus timer for macOS, iPadOS, and iOS. The macOS app has a main window plus a `MenuBarExtra` popover, while the iPadOS and iOS app has a single timer view. All surfaces are driven by one shared timer engine.

## Commands

Build and test via `xcodebuild` (scheme: `Orbit`):

```bash
xcodebuild -scheme Orbit -project Orbit.xcodeproj build
```

```bash
xcodebuild -scheme Orbit -project Orbit.xcodeproj test
```

Run a single test (Swift Testing framework, used by `OrbitTests`):

```bash
xcodebuild -scheme Orbit -project Orbit.xcodeproj test -only-testing:OrbitTests/OrbitTests/presetChangesRemainingWhileIdle
```

Run just the UI tests target (XCTest):

```bash
xcodebuild -scheme Orbit -project Orbit.xcodeproj test -only-testing:OrbitUITests
```

There is no SPM `Package.swift` or separate lint config — this is a plain Xcode project (`Orbit.xcodeproj`).

## Architecture

**Single source of truth:** `TimerEngine` (`Orbit/AppCore/Core/TimerEngine.swift`) is the one `@MainActor` `ObservableObject` created in `OrbitApp` and injected via `.environmentObject` into platform-specific scenes. There is no per-view state duplication: the macOS main window, macOS menu bar popover, and iPadOS/iOS app screen are renderings of the same engine.

- **Source layout**: `Orbit/AppCore` contains shared app, engine, service, design-system, and reusable view code. `Orbit/Mac` contains macOS-specific views. `Orbit/iPadOS-iOS` contains iPhone and iPad-specific views.
- **UI test layout**: `OrbitUITests/AppCore` contains shared UI test helpers. `OrbitUITests/Mac` contains macOS-specific UI tests. `OrbitUITests/iPadOS-iOS` contains iPhone and iPad-specific UI tests.
- **Phase state machine**: `TimerPhase` is `.idle → .running ⇄ .paused → .complete → .idle`. All views branch on `engine.phase` to decide which controls to show (see the `controls` computed views in `MacTimerView`, `IOSTimerView`, and `MenuBarContentView`, which are structurally duplicated between the app surfaces).
- **Wall-clock timing, not tick-counting**: running state is tracked via an `endDate` (`Date`), and a 0.25s repeating `Timer` just recomputes `remaining = endDate.timeIntervalSinceNow`. This means pause/resume and elapsed time stay correct across sleep/backgrounding without drift accumulation from tick counting.
- **Views are dumb**: `TimerDialView` (the circular progress ring), `MacTimerView`, `IOSTimerView`, and `MenuBarContentView`/`MenuBarLabel` only read `engine` and call its methods (`start`, `pause`, `stop`, `selectPreset`, `startAnother`); no view owns timer logic itself.
- **Side effects live in `NotificationManager`** (`Orbit/AppCore/Services/NotificationManager.swift`), a plain singleton (not an `ObservableObject`) that `TimerEngine.complete()` calls directly to fire a `UNUserNotificationCenter` alert and play a system sound where supported.
- **Styling is centralized** in `Orbit/AppCore/DesignSystem/EmberStyle.swift`: the `EmberColor` gradient and three `ButtonStyle`s (`EmberRoundButtonStyle`, `EmberPillButtonStyle`, `EmberTextButtonStyle`) used everywhere instead of ad hoc modifiers, plus a `Color(hex:)` initializer.
- **Previews as fixtures**: `TimerEngine` has `completedPreview()`/`runningPreview()` helpers used by SwiftUI `#Preview` blocks to exercise non-idle states without going through real timing/notifications — reuse this pattern rather than hand-rolling preview state.

Note: `OrbitTests.swift` currently expects `TimerEngine.defaultDuration` to be `.minutes(30)` with presets `[15, 30, 45, 60]`.

## Implementation Notes

- Preserve the shared-engine model between platform-specific app views and the macOS menu bar UI.
- Keep views mostly declarative: read from `engine`, bind simple editable values, and call engine methods.
- If adding timer states or controls, update `MacTimerView`, `IOSTimerView`, and `MenuBarContentView` unless the behavior is intentionally scene-specific.
- Keep state mutations for `TimerEngine` on the main actor.
- Keep variable declarations for UI elements at the bottom of the scope so the main view flow stays easy to scan.
- Add comments for every declared variable and function, including UI properties and helper methods. Use Swift doc comments (`///`) for functions. Start each function docstring with a short summary sentence, then add a blank doc-comment line before any structured details. For functions with parameters, include a `- Parameters:` section with one indented bullet per parameter that explains its role. For functions that return a value, include a `- Returns:` section that describes what comes back. Omit sections that do not apply.
- Avoid broad refactors unless they directly support the requested change.

## Git Hygiene

- The worktree may contain user edits. Do not revert changes you did not make.
- Keep edits scoped to the requested task.
- Avoid committing unless the user explicitly asks for a commit.

## Swift Documentation Comments

When documenting Swift functions, methods, and initializers, use Swift documentation comments (`///`) with Swift Markdown documentation syntax.

Follow these formatting rules:

- Begin with a concise summary sentence.
- Add a blank documentation line (`///`) before documentation fields.
- Group documentation under semantic fields such as `- Parameters:`, `- Returns:`, `- Throws:`, `- Precondition:`, and similar sections.
- When a field contains multiple items, indent each item beneath its field.
- Nested items must be visually tabbed/indented under the field they belong to.
- Never place multiple parameter, return, or error descriptions at the same indentation level as the field heading.
- Use consistent indentation of two spaces after `///` for nested documentation items.

Example:

```swift
/// Calculates pricing information for an order.
///
/// - Parameters:
///   - price: The price before tax.
///   - taxRate: The tax rate as a decimal.
///   - discountRate: The discount rate as a decimal.
/// - Returns:
///   - subtotal: The price after applying the discount.
///   - total: The final price including tax.
/// - Throws:
///   - PricingError.invalidPrice: If the supplied price is negative.
///   - PricingError.invalidTaxRate: If the tax rate is invalid.
func calculateTotal(
    price: Double,
    taxRate: Double,
    discountRate: Double
) throws -> (subtotal: Double, total: Double) {
    // ...
}
```
