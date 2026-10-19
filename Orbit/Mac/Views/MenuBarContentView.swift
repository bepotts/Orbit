//
//  MenuBarContentView.swift
//  Orbit
//

import os
import SwiftUI

#if os(macOS)
    struct MenuBarLabel: View {
        /// Shared timer state used to decide whether the menu bar should show a countdown.
        @Environment(TimerEngine.self) private var engine

        /// Compact menu bar label with the flame icon and optional remaining time.
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                if engine.phase == .running || engine.phase == .paused {
                    Text(engine.formattedRemaining)
                        .monospacedDigit()
                        .accessibilityIdentifier("menuBarRemainingText")
                }
            }
        }
    }

    struct MenuBarContentView: View {
        /// Shared timer state that powers the menu bar controls and dial.
        @Environment(TimerEngine.self) private var engine
        /// Focus target used to return keyboard focus to the active primary control.
        @FocusState private var focusedControl: FocusedControl?
        /// Logger used to record menu bar view lifecycle and interaction events.
        private let logger = Logger.views

        /// Popover content shown from the menu bar extra.
        var body: some View {
            VStack(spacing: 16) {
                TimerDialView(diameter: 140, timeFontSize: 30) {
                    focusedControl = .primaryButton
                }

                if engine.phase == .idle {
                    HStack(spacing: 6) {
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

                controls

                Divider()

                Button("Quit Orbit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(EmberTextButtonStyle())
                .focused($focusedControl, equals: .quitButton)
                .onKeyPress(.return) {
                    performFocusedAction({ NSApplication.shared.terminate(nil) }, refocusing: .quitButton)
                    return .handled
                }
            }
            .padding(18)
            .frame(width: 220)
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

        /// Menu bar version of the timer controls for the current phase.
        @ViewBuilder
        private var controls: some View {
            switch engine.phase {
            case .idle:
                playButton

            case .running:
                HStack(spacing: 14) {
                    pauseButton
                    stopButton
                }

            case .paused:
                HStack(spacing: 14) {
                    playButton
                    stopButton
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

        /// Primary play control that starts or resumes the timer.
        private var playButton: some View {
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
        }

        /// Secondary pause control shown while the timer is running.
        private var pauseButton: some View {
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
        }

        /// Text control that stops the current timer session.
        private var stopButton: some View {
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
        MenuBarContentView()
            .environment(TimerEngine())
    }

    #Preview("Dark") {
        MenuBarContentView()
            .environment(TimerEngine())
            .preferredColorScheme(.dark)
    }
#endif
