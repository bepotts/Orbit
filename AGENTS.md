# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

TimeOnTask, also called Ember in parts of the codebase, is a native SwiftUI focus timer for macOS, iPadOS, and iOS.

The macOS app has a main window and a `MenuBarExtra` popover. The iPadOS and iOS app has a single timer view. All surfaces are driven by the same shared timer model.

## Commands

Build:

```bash
xcodebuild -scheme TimeOnTask -project TimeOnTask.xcodeproj build
```

Run all tests:

```bash
xcodebuild -scheme TimeOnTask -project TimeOnTask.xcodeproj test
```

Run a single Swift Testing test:

```bash
xcodebuild -scheme TimeOnTask -project TimeOnTask.xcodeproj test -only-testing:TimeOnTaskTests/TimeOnTaskTests/presetChangesRemainingWhileIdle
```

Run only UI tests:

```bash
xcodebuild -scheme TimeOnTask -project TimeOnTask.xcodeproj test -only-testing:TimeOnTaskUITests
```

## Core instructions
* Target iOS 26.0 or later. (Yes, it definitely exists.)
* Swift 6.2 or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
* SwiftUI backed up by @Observable classes for shared data.
* Do not introduce third-party frameworks without asking first.
* Avoid UIKit unless requested.

## Swift instructions

- `@Observable` classes must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless they are unavoidable, or if they exist in legacy/integration contexts when changing architecture would be complicated.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`. Always use the modern `FormatStyle` API instead. For example, to format a date, use `myDate.formatted(date: .abbreviated, time: .shortened)`. To parse a date from a string, use `Date(inputString, strategy: .iso8601)`. For numbers, use `myNumber.formatted(.number)` or custom format styles.

## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Use the newest ScrollView APIs for item scrolling and positioning (e.g. `ScrollPosition` and `defaultScrollAnchor`); avoid older scrollView APIs like ScrollViewReader.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.


## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.

## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols such as  `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.

## Architecture

- `TimeOnTask/AppCore/App/TimeOnTaskApp.swift` creates one `@StateObject` `TimerEngine` and injects it into platform-specific scenes with `.environmentObject`.
- `TimeOnTask/AppCore/Core/TimerEngine.swift` is the single source of truth for timer state and behavior. Keep timer logic out of views.
- `TimeOnTask/AppCore` contains code shared by the macOS and iPadOS/iOS app surfaces.
- `TimeOnTask/Mac` contains macOS-specific views, including the main window and menu bar UI.
- `TimeOnTask/iPadOS-iOS` contains iPhone and iPad-specific views.
- `TimeOnTaskUITests/AppCore` contains shared UI test helpers.
- `TimeOnTaskUITests/Mac` contains macOS-specific UI tests.
- `TimeOnTaskUITests/iPadOS-iOS` contains iPhone and iPad-specific UI tests.
- `TimerPhase` follows `idle -> running <-> paused -> complete -> idle`.
- Running timers use wall-clock time through `endDate`, while a repeating `Timer` only refreshes display state. Avoid replacing this with tick-counting logic.
- `TimeOnTask/AppCore/Services/NotificationManager.swift` owns notification and sound side effects.
- `TimeOnTask/AppCore/DesignSystem/EmberStyle.swift` centralizes colors and button styles. Prefer existing design-system types over ad hoc styling.
- SwiftUI previews should use `TimerEngine` preview helpers instead of creating view-owned timer state.

## Implementation Notes

- Preserve the shared-engine model between platform-specific app views and the macOS menu bar UI.
- Keep views mostly declarative: read from `engine`, bind simple editable values, and call engine methods.
- If adding timer states or controls, update `MacTimerView`, `IOSTimerView`, and `MenuBarContentView` unless the behavior is intentionally scene-specific.
- Keep state mutations for `TimerEngine` on the main actor.
- Keep stored property declarations for UI elements at the top of the type's scope, before `body` and methods. This includes constants and properties using wrappers such as `@State`, `@Binding`, `@Environment`, and `@FocusState`.
- Add comments for every declared variable, function, and enum, including UI properties, helper methods, enum types, and enum cases. Use Swift doc comments (`///`) for functions and enums. Start each function docstring with a short summary sentence, then add a blank doc-comment line before any structured details. For functions with parameters, include a `- Parameters:` section with one indented bullet per parameter that explains its role. For functions that return a value, include a `- Returns:` section that describes what comes back. Omit sections that do not apply.
- Avoid broad refactors unless they directly support the requested change.

## Testing Notes

The tests in `TimeOnTaskTests.swift` expect `TimerEngine.defaultDuration` to be 30 minutes and presets to be 15, 30, 45, and 60 minutes.

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
