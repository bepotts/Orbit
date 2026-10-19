//
//  TimerEngine.swift
//  Orbit
//

import Foundation
import Observation
import os

/// Coordinates timer state, countdown timing, and completion side effects.
@MainActor
@Observable
final class TimerEngine {
    /// Default session length used when a timer engine is created without a custom duration.
    nonisolated static let defaultDuration: TimeInterval = .minutes(30)
    /// Largest session length the timer accepts from manual entry or presets.
    nonisolated static let maximumDuration: TimeInterval = .init(maximumDisplayMinutes * 60 + maximumDisplaySeconds)
    /// Largest minute value shown in the editable timer display.
    private nonisolated static let maximumDisplayMinutes = 99
    /// Largest second value shown in the editable timer display.
    private nonisolated static let maximumDisplaySeconds = 99
    /// Preset session lengths shown in the UI for quick timer selection.
    nonisolated static let presets: [TimeInterval] = [
        .minutes(15),
        defaultDuration,
        .minutes(45),
        .minutes(60),
    ]
    /// Suggested names for focused study sessions.
    nonisolated static let sessionLabelSuggestions: [String] = [
        "Chapter Champion",
        "Library Lock-In",
        "Flashcard Forge",
        "Exam Arc",
        "Notes Nebula",
        "Scholar Sprint",
        "Study Sanctum",
        "Thesis Time",
        "Page Turner Protocol",
        "Quiz Quest",
        "Cram Castle",
        "Proof Patrol",
        "Textbook Takedown",
        "Citation Station",
        "Syllabus Slayer",
        "Lecture Lab",
        "Brain Buffet",
        "The Reading Room",
        "Homework Helm",
        "Focus Fellowship",
        "Knowledge Knockout",
        "Research Reactor",
        "Outline Odyssey",
        "The Serious Study",
        "Worksheet Warp",
        "Index Card Inferno",
        "Concept Crucible",
        "Paragraph Pilgrimage",
        "Seminar Sprint",
        "Study Hall Prime",
    ]

    /// Current lifecycle state that drives the visible controls and timer behavior.
    private(set) var phase: TimerPhase = .idle
    /// Amount of time left in the current or selected session.
    private(set) var remaining: TimeInterval
    /// Selected session length that idle timers start from.
    var duration: TimeInterval
    /// Optional user-entered label used when naming and announcing the completed session.
    var sessionLabel: String

    /// Session length captured at start time so progress remains stable during a run.
    @ObservationIgnored
    private var totalDuration: TimeInterval
    /// Wall-clock finish time used to calculate remaining time accurately.
    @ObservationIgnored
    private var endDate: Date?
    /// Repeating timer that refreshes the engine while a session is running.
    @ObservationIgnored
    private var timer: Timer?
    /// Logger used to record timer engine lifecycle events.
    @ObservationIgnored
    private let logger = Logger.services

    /// Creates a timer engine with a selected duration.
    ///
    /// - Parameters:
    ///   - duration: The starting timer length in seconds.
    ///   - sessionLabel: The starting label shown in the session name field.
    init(
        duration: TimeInterval = TimerEngine.defaultDuration,
        sessionLabel: String = TimerEngine.randomSessionLabel(),
    ) {
        // Bounded starting value that keeps externally constructed engines within the displayable range.
        let clamped = TimerEngine.clampedDuration(duration)
        self.duration = clamped
        self.sessionLabel = sessionLabel
        totalDuration = clamped
        remaining = clamped
    }

    /// Fraction of the active session that has elapsed, used by the circular progress ring.
    var progress: Double {
        guard totalDuration > 0 else {
            return 0
        }
        return min(1, max(0, 1 - (remaining / totalDuration)))
    }

    /// Remaining time formatted for display in the timer views.
    var formattedRemaining: String {
        let components = TimerEngine.displayComponents(for: remaining)
        let minutes = components.minutes.formatted(.number.precision(.integerLength(2)))
        let seconds = components.seconds.formatted(.number.precision(.integerLength(2)))
        return "\(minutes):\(seconds)"
    }

    /// Remaining time split into the editable display's minute and second fields.
    var displayComponents: (minutes: Int, seconds: Int) {
        TimerEngine.displayComponents(for: remaining)
    }

    /// Selects a preset duration while the timer is idle.
    ///
    /// - Parameters:
    ///   - seconds: The preset duration to apply in seconds.
    func selectPreset(_ seconds: TimeInterval) {
        guard phase == .idle else {
            return
        }
        let clamped = TimerEngine.clampedDuration(seconds)
        duration = clamped
        remaining = clamped
        totalDuration = clamped
    }

    /// Applies a user-entered duration from the timer display.
    ///
    /// - Parameters:
    ///   - seconds: The manually entered duration to apply in seconds.
    func setManualDuration(_ seconds: TimeInterval) {
        guard phase == .idle || phase == .paused else {
            return
        }
        let clamped = TimerEngine.clampedDuration(seconds)
        duration = clamped
        remaining = clamped
        totalDuration = clamped
    }

    /// Restricts a proposed duration to the supported timer range.
    ///
    /// - Parameters:
    ///   - seconds: The proposed duration in seconds.
    /// - Returns: The duration clamped between zero and the maximum displayable timer value.
    private nonisolated static func clampedDuration(_ seconds: TimeInterval) -> TimeInterval {
        min(max(0, seconds), maximumDuration)
    }

    /// Selects a random suggested label for a new focused session.
    ///
    /// - Returns: A whimsical default session label.
    private nonisolated static func randomSessionLabel() -> String {
        sessionLabelSuggestions.randomElement() ?? "Focused Session"
    }

    /// Converts seconds into the editable display's bounded MM:SS-style components.
    ///
    /// Values above `99:59` continue counting down in the final minute bucket so `99:99`
    /// is the largest visible value while each displayed second still changes by one.
    ///
    /// - Parameters:
    ///   - seconds: The duration to format for display.
    /// - Returns: The minute and second values to render in the timer display.
    private nonisolated static func displayComponents(for seconds: TimeInterval) -> (minutes: Int, seconds: Int) {
        // Rounded-up whole seconds so the display does not show the next minute too early.
        let total = Int(clampedDuration(seconds).rounded(.up))
        let minutes = total / 60
        guard minutes >= maximumDisplayMinutes else {
            return (minutes, total % 60)
        }
        return (maximumDisplayMinutes, total - maximumDisplayMinutes * 60)
    }

    /// Starts or resumes the current timer session.
    func start() {
        guard phase == .idle || phase == .paused else {
            return
        }
        logger.debug("Timer engine started")
        if phase == .idle {
            totalDuration = duration
            remaining = duration
        }
        phase = .running
        endDate = Date().addingTimeInterval(remaining)
        scheduleTick()
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }

    /// Pauses a running timer and preserves the wall-clock remaining time.
    func pause() {
        guard phase == .running else {
            return
        }
        timer?.invalidate()
        timer = nil
        // Captured end date used to convert the paused wall-clock state back into remaining seconds.
        if let endDate {
            remaining = max(0, endDate.timeIntervalSinceNow)
        }
        phase = .paused
    }

    /// Stops the active timer and resets it to the selected duration.
    func stop() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        phase = .idle
        remaining = duration
        totalDuration = duration
    }

    /// Resets a completed session so the user can start another timer.
    func startAnother() {
        stop()
    }

    /// Schedules the repeating display refresh timer for a running session.
    private func scheduleTick() {
        timer?.invalidate()
        // Repeating timer that asks the main actor to update remaining time.
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Refreshes remaining time from the current wall-clock end date.
    private func tick() {
        // Active finish time used to decide whether the session is still running.
        guard let endDate else {
            return
        }
        // Current remaining seconds based on the wall clock.
        let remainingNow = endDate.timeIntervalSinceNow
        if remainingNow <= 0 {
            remaining = 0
            complete()
        } else {
            remaining = remainingNow
        }
    }

    /// Marks the current session complete and triggers completion side effects.
    private func complete() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        phase = .complete
        NotificationManager.shared.notifySessionComplete(label: sessionLabel, minutes: Int(duration / 60))
    }
}

extension TimerEngine {
    /// Creates a preview timer engine in the completed phase.
    ///
    /// - Returns: A timer engine configured as an already completed session.
    static func completedPreview() -> TimerEngine {
        let engine = TimerEngine()
        engine.phase = .complete
        engine.remaining = 0
        return engine
    }
}

/// Lifecycle phases supported by the timer engine.
enum TimerPhase: Equatable {
    /// Timer is ready to start from the selected duration.
    case idle
    /// Timer is actively counting down.
    case running
    /// Timer is stopped temporarily with remaining time preserved.
    case paused
    /// Timer reached zero and is waiting to be reset.
    case complete
}

extension TimeInterval {
    /// Converts a whole-minute value into seconds for timer durations.
    ///
    /// - Parameters:
    ///   - value: The number of minutes to convert.
    /// - Returns: The equivalent duration in seconds.
    nonisolated static func minutes(_ value: Int) -> TimeInterval {
        TimeInterval(value * 60)
    }
}
