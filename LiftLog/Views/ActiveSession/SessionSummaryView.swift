import SwiftUI

struct SessionSummaryView: View {
    @ObservedObject var viewModel: ActiveSessionViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summaryHeader
                    statsRow
                    exerciseBreakdown
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(String(localized: "summary.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button(action: onDismiss) {
                Text(String(localized: "summary.back_to_calendar"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .padding(.top, 20)
            Text(String(localized: "summary.great_job"))
                .font(.title.bold())
            Text(String(localized: "summary.session_complete"))
                .foregroundColor(.secondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: viewModel.elapsedTime.formattedHoursDuration, label: String(localized: "summary.duration"))
            Divider().frame(height: 40)
            StatItem(value: String(format: "%.0f kg", viewModel.totalVolume), label: String(localized: "summary.volume"))
            Divider().frame(height: 40)
            StatItem(value: "\(viewModel.completedExercisesCount)", label: String(localized: "summary.exercises"))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "summary.breakdown"))
                .font(.headline)

            ForEach(viewModel.exerciseEntries.filter { !$0.skipped && !$0.completedSets.isEmpty }) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.exercise.name)
                        .font(.subheadline.bold())
                    ForEach(entry.completedSets) { set in
                        HStack {
                            Text(String(localized: "summary.set \(set.setNumber)"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if set.isBodyweight {
                                Text("\(set.repsDone) reps (BW)")
                                    .font(.caption.bold())
                            } else {
                                Text("\(set.repsDone) × \(set.weightKg.formattedWeight) kg")
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var shareText: String {
        var lines = ["💪 LiftLog Session Summary"]
        lines.append("Duration: \(viewModel.elapsedTime.formattedHoursDuration)")
        lines.append("Total Volume: \(String(format: "%.0f", viewModel.totalVolume)) kg")
        lines.append("")
        for entry in viewModel.exerciseEntries where !entry.skipped && !entry.completedSets.isEmpty {
            lines.append("• \(entry.exercise.name)")
            for set in entry.completedSets {
                if set.isBodyweight {
                    lines.append("  Set \(set.setNumber): \(set.repsDone) reps (BW)")
                } else {
                    lines.append("  Set \(set.setNumber): \(set.repsDone) × \(set.weightKg.formattedWeight) kg")
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
