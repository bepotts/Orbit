//
//  TimerDialView.swift
//  Orbit
//

import SwiftUI
#if os(macOS)
    import AppKit
#endif

struct TimerDialView: View {
    /// Shared timer state used to render progress, time, and status text.
    @Environment(TimerEngine.self) private var engine
    /// Diameter of the circular timer dial so the same view can fit window and menu bar layouts.
    var diameter: CGFloat = 220
    /// Font size for the central time display.
    var timeFontSize: CGFloat = 44
    /// Called after the fourth digit is entered so the containing view can move focus to its primary control.
    var onCompletedDigitEntry: () -> Void = {}

    /// Whether the time display is currently showing its editable digit boxes.
    @State private var isEditingTime = false
    /// Single-character contents of the four digit boxes: minutes tens, minutes ones, seconds tens, seconds ones.
    @State private var digits: [String] = ["", "", "", ""]
    /// Currently focused editable digit box, when the timer display is being edited.
    @FocusState private var focusedDigitIndex: Int?

    /// Time can only be hand-edited when the timer is not actively counting down.
    private var isTimeEditable: Bool {
        engine.phase == .idle || engine.phase == .paused
    }

    /// Short status string shown below the countdown.
    private var statusLabel: String {
        switch engine.phase {
        case .idle:
            "Ready"
        case .running:
            "Remaining"
        case .paused:
            "Paused"
        case .complete:
            "\(Int(engine.duration / 60)) minutes"
        }
    }

    // swiftlint:disable closure_body_length
    /// Circular progress display with the remaining time in the center.
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 10)

            Circle()
                .trim(from: 0, to: engine.phase == .idle ? 0 : engine.progress)
                .stroke(EmberColor.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: EmberColor.accentStart.opacity(engine.phase == .running ? 0.55 : 0), radius: 8)
                .animation(.linear(duration: 0.25), value: engine.progress)

            VStack(spacing: 6) {
                if engine.phase == .complete {
                    Text("Session complete")
                        .font(.system(size: timeFontSize * 0.34, weight: .medium))
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("timerCompleteText")
                        .accessibilityLabel("Session complete")
                } else if isEditingTime {
                    HStack(spacing: 4) {
                        digitBox(0)
                        digitBox(1)
                        Text(":")
                            .font(.system(size: timeFontSize * 0.7, weight: .medium, design: .monospaced))
                        digitBox(2)
                        digitBox(3)
                    }
                    .onChange(of: focusedDigitIndex) { _, focused in
                        if focused == nil {
                            commitEdit()
                        }
                    }
                } else {
                    Button {
                        beginEditing()
                    } label: {
                        Text(engine.formattedRemaining)
                            .font(.system(size: timeFontSize, weight: .medium, design: .monospaced))
                            .monospacedDigit()
                    }
                    .buttonStyle(.plain)
                    .disabled(!isTimeEditable)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("timerRemainingText")
                    .accessibilityLabel(engine.formattedRemaining)
                    #if os(macOS)
                        .onHover { hovering in
                            guard isTimeEditable else {
                                return
                            }
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    #endif
                }
                Text(statusLabel)
                    .font(.system(size: 11))
                    .kerning(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("timerStatusText")
                    .accessibilityLabel(statusLabel)
            }
            .padding(.horizontal, 12)
        }
        .frame(width: diameter, height: diameter)
    }

    // swiftlint:enable closure_body_length

    /// Builds a single digit entry box for the editable MM:SS display.
    ///
    /// - Parameters:
    ///   - index: The digit index to display and bind.
    /// - Returns: The configured digit entry view.
    private func digitBox(_ index: Int) -> some View {
        TextField("", text: digitBinding(index))
            .font(.system(size: timeFontSize * 0.82, weight: .medium, design: .monospaced))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .frame(width: timeFontSize * 0.62, height: timeFontSize * 1.05)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(focusedDigitIndex == index ? 0.35 : 0.12), lineWidth: 1.5),
            )
            .contentShape(Rectangle())
            .focused($focusedDigitIndex, equals: index)
            .accessibilityIdentifier("timerDigit\(index)Field")
            .onSubmit { advanceFocus(from: index) }
            .onKeyPress { press in
                guard let typed = press.characters.last, typed.isASCII, typed.isNumber else {
                    return .ignored
                }
                setDigitFromKeystroke(typed, at: index)
                return .handled
            }
            .onKeyPress(.return) {
                advanceFocus(from: index)
                return .handled
            }
            .onKeyPress(.delete) {
                guard digits[index].isEmpty else {
                    return .ignored
                }
                moveFocusBackward(from: index)
                return .handled
            }
    }

    /// Creates a binding that filters each box down to a single digit.
    ///
    /// - Parameters:
    ///   - index: The digit index the binding reads and writes.
    /// - Returns: A text binding for the selected digit box.
    private func digitBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { digits[index] },
            set: { newValue in setDigit(newValue, at: index) },
        )
    }

    /// Handles physical digit keys so typing over a prefilled box advances immediately.
    ///
    /// - Parameters:
    ///   - typed: The numeric character entered from the keyboard.
    ///   - index: The digit index to replace.
    private func setDigitFromKeystroke(_ typed: Character, at index: Int) {
        digits[index] = String(typed)
        advanceFocus(from: index)
    }

    /// Stores a typed digit and advances focus when the input is valid.
    ///
    /// - Parameters:
    ///   - newValue: The new text value SwiftUI is attempting to store.
    ///   - index: The digit index to update.
    private func setDigit(_ newValue: String, at index: Int) {
        let old = digits[index]
        guard newValue.count > old.count, let typed = newValue.last else {
            // Deletion (or no net growth): keep only digits, dropping anything non-numeric.
            digits[index] = String(newValue.filter { $0.isASCII && $0.isNumber }.suffix(1))
            return
        }
        guard typed.isASCII, typed.isNumber else {
            return
        }
        digits[index] = String(typed)
        advanceFocus(from: index)
    }

    /// Moves focus to the next digit box or commits after the final box.
    ///
    /// - Parameters:
    ///   - index: The digit index that just finished editing.
    private func advanceFocus(from index: Int) {
        guard index < digits.count - 1 else {
            commitEdit()
            Task { @MainActor in
                onCompletedDigitEntry()
            }
            return
        }
        let nextIndex = index + 1
        Task { @MainActor in
            focusedDigitIndex = nextIndex
        }
    }

    /// Moves focus backward and clears the previous digit during deletion.
    ///
    /// - Parameters:
    ///   - index: The currently focused digit index.
    private func moveFocusBackward(from index: Int) {
        guard index > 0 else {
            return
        }
        digits[index - 1] = ""
        focusedDigitIndex = index - 1
    }

    /// Switches the time display into editable digit boxes pre-filled with the current time.
    private func beginEditing() {
        guard isTimeEditable else {
            return
        }
        let components = engine.displayComponents
        digits = [
            String(components.minutes / 10),
            String(components.minutes % 10),
            String(components.seconds / 10),
            String(components.seconds % 10),
        ]
        isEditingTime = true
        focusedDigitIndex = 0
    }

    /// Applies the entered MM:SS digits as the timer's manual duration.
    private func commitEdit() {
        guard isEditingTime else {
            return
        }
        let values = digits.map { Int($0) ?? 0 }
        let minutes = values[0] * 10 + values[1]
        let seconds = values[2] * 10 + values[3]
        let duration = TimeInterval(minutes * 60 + seconds)
        isEditingTime = false
        focusedDigitIndex = nil
        // Defer the published engine update until SwiftUI finishes the current focus/view update pass.
        Task { @MainActor in
            engine.setManualDuration(duration)
        }
    }
}

#Preview("Idle") {
    TimerDialView()
        .environment(TimerEngine())
        .padding(40)
}

#Preview("Idle - Dark") {
    TimerDialView()
        .environment(TimerEngine())
        .padding(40)
        .preferredColorScheme(.dark)
}

#Preview("Running") {
    TimerDialView()
        .environment(TimerEngine.runningPreview())
        .padding(40)
}

#Preview("Running - Dark") {
    TimerDialView()
        .environment(TimerEngine.runningPreview())
        .padding(40)
        .preferredColorScheme(.dark)
}

#Preview("Complete") {
    TimerDialView()
        .environment(TimerEngine.completedPreview())
        .padding(40)
}

#Preview("Complete - Dark") {
    TimerDialView()
        .environment(TimerEngine.completedPreview())
        .padding(40)
        .preferredColorScheme(.dark)
}

private extension TimerEngine {
    /// Creates a running timer engine for previews.
    ///
    /// - Returns: A timer engine configured as actively running.
    static func runningPreview() -> TimerEngine {
        let engine = TimerEngine()
        engine.start()
        return engine
    }
}
