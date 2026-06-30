import Foundation
import SwiftUI
import UIKit

struct SessionExerciseEntry: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var sets: [SessionSet]
    var notesExpanded: Bool = false
    var notes: String = ""
    var skipped: Bool = false

    var completedSets: [SessionSet] {
        sets.filter { $0.completed }
    }
}

@MainActor
final class ActiveSessionViewModel: ObservableObject {
    @Published var session: Session
    @Published var exerciseEntries: [SessionExerciseEntry] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var restTimerActive = false
    @Published var restTimeRemaining: Int = 0
    @Published var restTimerTotal: Int = 90
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showSummary = false
    @Published var error: AppError?

    private var timer: Timer?
    private var restTimer: Timer?
    private var startDate: Date?

    init(session: Session) {
        self.session = session
    }

    func setup(planExercises: [PlanExercise]) {
        exerciseEntries = planExercises.compactMap { pe in
            guard let exercise = pe.exercise else { return nil }
            let sets = (1...pe.sets).map { i in
                SessionSet(sessionId: session.id, exerciseId: exercise.id, setNumber: i)
            }
            return SessionExerciseEntry(exercise: exercise, sets: sets)
        }
        startSession()
    }

    func setupFreeSession(exercises: [Exercise]) {
        exerciseEntries = exercises.map { exercise in
            let sets = [SessionSet(sessionId: session.id, exerciseId: exercise.id, setNumber: 1)]
            return SessionExerciseEntry(exercise: exercise, sets: sets)
        }
        startSession()
    }

    private func startSession() {
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            Task { @MainActor in
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
        Task {
            try? await SessionService.shared.startSession(id: session.id)
        }
    }

    func completeSet(entryId: UUID, setId: UUID, restSeconds: Int) {
        guard let entryIdx = exerciseEntries.firstIndex(where: { $0.id == entryId }),
              let setIdx = exerciseEntries[entryIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exerciseEntries[entryIdx].sets[setIdx].completed = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if restSeconds > 0 {
            startRestTimer(seconds: restSeconds)
        }
    }

    func uncompleteSet(entryId: UUID, setId: UUID) {
        guard let entryIdx = exerciseEntries.firstIndex(where: { $0.id == entryId }),
              let setIdx = exerciseEntries[entryIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exerciseEntries[entryIdx].sets[setIdx].completed = false
    }

    func addSet(to entryId: UUID) {
        guard let idx = exerciseEntries.firstIndex(where: { $0.id == entryId }) else { return }
        let entry = exerciseEntries[idx]
        let newSetNumber = (entry.sets.map { $0.setNumber }.max() ?? 0) + 1
        let newSet = SessionSet(sessionId: session.id, exerciseId: entry.exercise.id, setNumber: newSetNumber)
        exerciseEntries[idx].sets.append(newSet)
    }

    func skipExercise(entryId: UUID) {
        guard let idx = exerciseEntries.firstIndex(where: { $0.id == entryId }) else { return }
        exerciseEntries[idx].skipped = true
    }

    func updateSetReps(entryId: UUID, setId: UUID, reps: Int) {
        guard let entryIdx = exerciseEntries.firstIndex(where: { $0.id == entryId }),
              let setIdx = exerciseEntries[entryIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exerciseEntries[entryIdx].sets[setIdx].repsDone = reps
    }

    func updateSetWeight(entryId: UUID, setId: UUID, weight: Double) {
        guard let entryIdx = exerciseEntries.firstIndex(where: { $0.id == entryId }),
              let setIdx = exerciseEntries[entryIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exerciseEntries[entryIdx].sets[setIdx].weightKg = weight
    }

    func updateSetBodyweight(entryId: UUID, setId: UUID, isBodyweight: Bool) {
        guard let entryIdx = exerciseEntries.firstIndex(where: { $0.id == entryId }),
              let setIdx = exerciseEntries[entryIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        exerciseEntries[entryIdx].sets[setIdx].isBodyweight = isBodyweight
    }

    private func startRestTimer(seconds: Int) {
        restTimer?.invalidate()
        restTimeRemaining = seconds
        restTimerTotal = seconds
        restTimerActive = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.restTimerActive = false
                    t.invalidate()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }

    func dismissRestTimer() {
        restTimer?.invalidate()
        restTimerActive = false
    }

    func editRestTimer(seconds: Int) {
        restTimer?.invalidate()
        startRestTimer(seconds: seconds)
    }

    func endSession(notes: String) async {
        timer?.invalidate()
        restTimer?.invalidate()
        isSaving = true
        defer { isSaving = false }
        do {
            try await SessionService.shared.endSession(id: session.id, notes: notes)
            let allSets = exerciseEntries
                .filter { !$0.skipped }
                .flatMap { $0.sets }
            try await SessionService.shared.saveSets(allSets, sessionId: session.id)
            showSummary = true
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    var totalVolume: Double {
        exerciseEntries
            .flatMap { $0.sets }
            .filter { $0.completed }
            .reduce(0) { $0 + $1.volume }
    }

    var completedExercisesCount: Int {
        exerciseEntries.filter { !$0.completedSets.isEmpty && !$0.skipped }.count
    }
}
