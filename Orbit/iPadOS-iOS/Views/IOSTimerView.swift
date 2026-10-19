//
//  IOSTimerView.swift
//  Orbit
//
//  Created by Brandon Potts on 8/16/26.
//

import SwiftUI

#if os(iOS)
    struct IOSTimerView: View {
        /// Shared timer state that drives the iOS timer display and actions.
        @Environment(TimerEngine.self) private var engine
        /// Focus target used to return keyboard focus to the primary control after editing.
        @FocusState private var focusedControl: FocusedControl?

        /// Main iPhone and iPad timer layout with session naming, dial, controls, and presets.
        var body: some View {
            @Bindable var engine = engine

            VStack(spacing: 22) {
                TextField("Name this session", text: $engine.sessionLabel)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .disabled(engine.phase != .idle)
                    .accessibilityIdentifier("sessionLabelField")

                TimerDialView {
                    focusedControl = .primaryButton
                }

                controls

                if engine.phase == .idle {
                    presetPills
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                Task { @MainActor in
                    focusedControl = .primaryButton
                }
            }
            .onChange(of: engine.phase) { _, phase in
                guard phase == .complete else {
                    return
                }
                Task { @MainActor in
                    focusedControl = .primaryButton
                }
            }
        }

        /// Start, pause, stop, or restart controls for the current timer phase.
        @ViewBuilder
        private var controls: some View {
            switch engine.phase {
            case .idle:
                Button("Start timer", systemImage: "play.fill") {
                    engine.start()
                    focusedControl = .primaryButton
                }
                .labelStyle(.iconOnly)
                .buttonStyle(EmberRoundButtonStyle(filled: true))
                .focused($focusedControl, equals: .primaryButton)
                .accessibilityIdentifier("startTimerButton")
                .onKeyPress(.return) {
                    performFocusedAction(engine.start, refocusing: .primaryButton)
                    return .handled
                }

            case .running:
                HStack(spacing: 18) {
                    Button("Pause timer", systemImage: "pause.fill") {
                        engine.pause()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(EmberRoundButtonStyle(filled: false))
                    .focused($focusedControl, equals: .primaryButton)
                    .accessibilityIdentifier("pauseTimerButton")
                    .onKeyPress(.return) {
                        performFocusedAction(engine.pause, refocusing: .primaryButton)
                        return .handled
                    }

                    Button("Stop") {
                        engine.stop()
                        focusedControl = .primaryButton
                    }
                    .buttonStyle(EmberTextButtonStyle())
                    .focused($focusedControl, equals: .stopButton)
                    .accessibilityIdentifier("stopTimerButton")
                    .onKeyPress(.return) {
                        performFocusedAction(engine.stop, refocusing: .primaryButton)
                        return .handled
                    }
                }

            case .paused:
                HStack(spacing: 18) {
                    Button("Start timer", systemImage: "play.fill") {
                        engine.start()
                        focusedControl = .primaryButton
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(EmberRoundButtonStyle(filled: true))
                    .focused($focusedControl, equals: .primaryButton)
                    .accessibilityIdentifier("startTimerButton")
                    .onKeyPress(.return) {
                        performFocusedAction(engine.start, refocusing: .primaryButton)
                        return .handled
                    }

                    Button("Stop") {
                        engine.stop()
                        focusedControl = .primaryButton
                    }
                    .buttonStyle(EmberTextButtonStyle())
                    .focused($focusedControl, equals: .stopButton)
                    .accessibilityIdentifier("stopTimerButton")
                    .onKeyPress(.return) {
                        performFocusedAction(engine.stop, refocusing: .primaryButton)
                        return .handled
                    }
                }

            case .complete:
                Button("Start another") {
                    engine.startAnother()
                    focusedControl = .primaryButton
                }
                .buttonStyle(EmberTextButtonStyle())
                .focused($focusedControl, equals: .primaryButton)
                .accessibilityIdentifier("startAnotherButton")
                .onKeyPress(.return) {
                    performFocusedAction(engine.startAnother, refocusing: .primaryButton)
                    return .handled
                }
            }
        }

        /// Idle-only preset buttons that let the user choose a session duration.
        private var presetPills: some View {
            HStack(spacing: 8) {
                ForEach(TimerEngine.presets, id: \.self) { preset in
                    Button("\(Int(preset / 60))") {
                        engine.selectPreset(preset)
                    }
                    .buttonStyle(EmberPillButtonStyle(active: engine.duration == preset))
                    .focused($focusedControl, equals: .presetButton(preset))
                    .accessibilityIdentifier("preset\(Int(preset / 60))Button")
                    .onKeyPress(.return) {
                        performFocusedAction(
                            { engine.selectPreset(preset) },
                            refocusing: .presetButton(preset),
                        )
                        return .handled
                    }
                }
            }
        }

        /// Performs a button action and restores focus after any resulting view update.
        ///
        /// - Parameters:
        ///   - action: The button action to run on the next main-loop pass.
        ///   - control: The focus target that should remain active after the action completes.
        private func performFocusedAction(_ action: @escaping () -> Void, refocusing control: FocusedControl) {
            Task { @MainActor in
                action()
                Task { @MainActor in
                    focusedControl = control
                }
            }
        }
    }

    #Preview("Light") {
        IOSTimerView()
            .environment(TimerEngine())
    }

    #Preview("Dark") {
        IOSTimerView()
            .environment(TimerEngine())
            .preferredColorScheme(.dark)
    }
#endif
