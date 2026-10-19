//
//  OrbitTests.swift
//  OrbitTests
//
//  Created by Brandon Potts on 8/16/26.
//

import Testing
@testable import Orbit

/// Unit tests for shared timer engine behavior.
@MainActor
struct OrbitTests {
    /// Verifies the timer engine starts with the expected default duration.
    @Test func defaultsToThirtyMinutes() {
        // Fresh timer engine used to verify default startup state.
        let engine = TimerEngine()
        #expect(engine.formattedRemaining == "30:00")
        #expect(engine.duration == .minutes(30))
    }

    /// Verifies selecting a preset updates the remaining time while idle.
    @Test func presetChangesRemainingWhileIdle() {
        // Fresh timer engine used to verify presets update idle remaining time.
        let engine = TimerEngine()
        engine.selectPreset(.minutes(45))
        #expect(engine.formattedRemaining == "45:00")
    }

    /// Verifies selecting a preset has no effect after the timer starts running.
    @Test func presetIsIgnoredOnceRunning() {
        // Fresh timer engine used to verify running timers ignore preset changes.
        let engine = TimerEngine()
        engine.start()
        engine.selectPreset(.minutes(60))
        #expect(engine.duration == .minutes(30))
    }

    /// Verifies stopping a timer resets it to the selected duration.
    @Test func stopResetsToChosenDuration() {
        // Fresh timer engine used to verify stop returns to the selected duration.
        let engine = TimerEngine()
        engine.selectPreset(.minutes(15))
        engine.start()
        engine.stop()
        #expect(engine.phase == .idle)
        #expect(engine.formattedRemaining == "15:00")
    }

    /// Verifies starting a timer moves the engine into the running phase.
    @Test func startTransitionsIdleTimerToRunning() {
        // Fresh timer engine used to verify the primary lifecycle transition.
        let engine = TimerEngine()
        engine.start()
        #expect(engine.phase == .running)
        #expect(engine.remaining <= engine.duration)
        #expect(engine.remaining > 0)
    }

    /// Verifies pausing a timer preserves remaining time without resetting the selected duration.
    @Test func pauseTransitionsRunningTimerToPaused() {
        // Fresh timer engine used to verify pausing keeps the current session intact.
        let engine = TimerEngine(duration: .minutes(15))
        engine.start()
        engine.pause()
        #expect(engine.phase == .paused)
        #expect(engine.duration == .minutes(15))
        #expect(engine.remaining <= .minutes(15))
        #expect(engine.remaining > 0)
    }

    /// Verifies pausing an idle timer has no effect.
    @Test func pauseIsIgnoredWhileIdle() {
        // Fresh timer engine used to verify invalid pause requests are ignored.
        let engine = TimerEngine(duration: .minutes(15))
        engine.pause()
        #expect(engine.phase == .idle)
        #expect(engine.remaining == .minutes(15))
    }

    /// Verifies manually entered timers can exceed one hour.
    @Test func manualDurationAllowsTimeAboveSixtyMinutes() {
        // Fresh timer engine used to verify long manual durations are accepted.
        let engine = TimerEngine()
        engine.setManualDuration(.minutes(90))
        #expect(engine.duration == .minutes(90))
        #expect(engine.formattedRemaining == "90:00")
    }

    /// Verifies manually entered timers cannot exceed the four-digit display maximum.
    @Test func manualDurationCapsAtNinetyNineNinetyNine() {
        // Fresh timer engine used to verify oversized manual durations are capped.
        let engine = TimerEngine()
        engine.setManualDuration(.minutes(120))
        #expect(engine.duration == TimerEngine.maximumDuration)
        #expect(engine.formattedRemaining == "99:99")
    }

    /// Verifies manually entered timers cannot go below zero.
    @Test func manualDurationFloorsAtZero() {
        // Fresh timer engine used to verify negative manual durations are clamped.
        let engine = TimerEngine()
        engine.setManualDuration(-10)
        #expect(engine.duration == 0)
        #expect(engine.remaining == 0)
        #expect(engine.formattedRemaining == "00:00")
    }

    /// Verifies an externally supplied starting duration is clamped into the supported range.
    @Test func initializerClampsDuration() {
        // Timer engine initialized with an oversized duration to verify construction bounds.
        let oversizedEngine = TimerEngine(duration: .minutes(120))
        // Timer engine initialized with a negative duration to verify construction bounds.
        let negativeEngine = TimerEngine(duration: -1)
        #expect(oversizedEngine.duration == TimerEngine.maximumDuration)
        #expect(oversizedEngine.remaining == TimerEngine.maximumDuration)
        #expect(negativeEngine.duration == 0)
        #expect(negativeEngine.remaining == 0)
    }

    /// Verifies manual duration changes are ignored while a timer is actively running.
    @Test func manualDurationIsIgnoredWhileRunning() {
        // Fresh timer engine used to verify active countdowns cannot be overwritten.
        let engine = TimerEngine(duration: .minutes(15))
        engine.start()
        engine.setManualDuration(.minutes(45))
        #expect(engine.duration == .minutes(15))
        #expect(engine.remaining <= .minutes(15))
    }

    /// Verifies manual duration changes are allowed while a timer is paused.
    @Test func manualDurationChangesPausedTimer() {
        // Fresh timer engine used to verify paused sessions can be edited.
        let engine = TimerEngine(duration: .minutes(15))
        engine.start()
        engine.pause()
        engine.setManualDuration(.minutes(45))
        #expect(engine.phase == .paused)
        #expect(engine.duration == .minutes(45))
        #expect(engine.remaining == .minutes(45))
        #expect(engine.formattedRemaining == "45:00")
    }

    /// Verifies stopping from a paused timer resets to the edited selected duration.
    @Test func stopAfterPausedEditResetsToEditedDuration() {
        // Fresh timer engine used to verify stop honors paused manual edits.
        let engine = TimerEngine(duration: .minutes(15))
        engine.start()
        engine.pause()
        engine.setManualDuration(.minutes(45))
        engine.stop()
        #expect(engine.phase == .idle)
        #expect(engine.remaining == .minutes(45))
        #expect(engine.progress == 0)
    }

    /// Verifies progress is zero before a session starts and after a stopped reset.
    @Test func progressIsZeroForIdleTimer() {
        // Fresh timer engine used to verify idle progress starts empty.
        let engine = TimerEngine(duration: .minutes(15))
        #expect(engine.progress == 0)
        engine.start()
        engine.stop()
        #expect(engine.progress == 0)
    }

    /// Verifies completed preview timers show finished progress.
    @Test func completedPreviewShowsFinishedProgress() {
        // Preview timer engine used to verify completed display state.
        let engine = TimerEngine.completedPreview()
        #expect(engine.phase == .complete)
        #expect(engine.remaining == 0)
        #expect(engine.progress == 1)
        #expect(engine.formattedRemaining == "00:00")
    }

    /// Verifies the focused session label suggestion pool has the requested number of names.
    @Test func sessionLabelSuggestionsContainThirtyNames() {
        #expect(TimerEngine.sessionLabelSuggestions.count == 30)
    }

    /// Verifies a fresh timer engine starts with a suggested session label.
    @Test func defaultsToSuggestedSessionLabel() {
        // Fresh timer engine used to verify startup labels come from the suggestion pool.
        let engine = TimerEngine()
        #expect(TimerEngine.sessionLabelSuggestions.contains(engine.sessionLabel))
    }
}
