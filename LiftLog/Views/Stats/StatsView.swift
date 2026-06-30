import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            TabView {
                ProgressionTab(viewModel: viewModel)
                    .tabItem { Label(String(localized: "stats.progression"), systemImage: "chart.line.uptrend.xyaxis") }
                ConsistencyTab(viewModel: viewModel)
                    .tabItem { Label(String(localized: "stats.consistency"), systemImage: "calendar.badge.checkmark") }
                MonthComparisonTab(viewModel: viewModel)
                    .tabItem { Label(String(localized: "stats.month_vs"), systemImage: "arrow.left.arrow.right") }
            }
            .navigationTitle(String(localized: "tab.stats"))
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
        .errorAlert(error: $viewModel.error)
    }
}

struct ProgressionTab: View {
    @ObservedObject var viewModel: StatsViewModel
    @StateObject private var libraryVM = ExerciseLibraryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                exercisePicker
                periodPicker
                chart
            }
            .padding(16)
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await libraryVM.load(userId: userId)
            }
        }
    }

    private var exercisePicker: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(viewModel.selectedExercise?.name ?? String(localized: "stats.select_exercise"))
                    .foregroundColor(viewModel.selectedExercise == nil ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            ExercisePickerView { exercise in
                viewModel.selectedExercise = exercise
            }
        }
    }

    private var periodPicker: some View {
        Picker(String(localized: "stats.period"), selection: $viewModel.selectedPeriod) {
            ForEach(StatsPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chart: some View {
        Group {
            let data = viewModel.progressionDataFiltered
            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(viewModel.selectedExercise == nil ?
                         String(localized: "stats.pick_exercise") :
                         String(localized: "stats.no_data"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.maxWeight)
                    )
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.maxWeight)
                    )
                }
                .frame(height: 220)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel { if let v = value.as(Double.self) { Text("\(v.formattedWeight) kg") } }
                        AxisGridLine()
                    }
                }
            }
        }
    }
}

struct ConsistencyTab: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                weeklyBarChart
                heatmapSection
                statsRow
            }
            .padding(16)
        }
    }

    private var weeklyBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "stats.weekly_sessions"))
                .font(.headline)

            Chart(viewModel.weeklySessionCounts) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Sessions", week.count)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "stats.heatmap"))
                .font(.headline)

            ContributionHeatmapView(
                days: viewModel.heatmapDays,
                sessionCountForDay: { viewModel.sessionsOnDay($0) }
            )
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(viewModel.currentStreak)", label: String(localized: "stats.current_streak"))
            Divider().frame(height: 40)
            StatItem(value: "\(viewModel.longestStreak)", label: String(localized: "stats.longest_streak"))
            Divider().frame(height: 40)
            StatItem(value: "\(viewModel.totalSessions)", label: String(localized: "stats.total_sessions"))
            Divider().frame(height: 40)
            StatItem(value: String(format: "%.0f", viewModel.totalVolume / 1000) + "t", label: String(localized: "stats.volume"))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ContributionHeatmapView: View {
    let days: [Date]
    let sessionCountForDay: (Date) -> Int

    private let columns = Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(days, id: \.self) { day in
                let count = sessionCountForDay(day)
                RoundedRectangle(cornerRadius: 2)
                    .fill(heatmapColor(count: count))
                    .frame(width: 12, height: 12)
            }
        }
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color(.systemFill)
        case 1: return Color.accentColor.opacity(0.35)
        case 2: return Color.accentColor.opacity(0.6)
        default: return Color.accentColor
        }
    }
}

struct MonthComparisonTab: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                comparisonHeader
                MetricComparisonRow(
                    title: String(localized: "stats.sessions"),
                    current: Double(viewModel.currentMonthMetrics.sessionCount),
                    previous: Double(viewModel.previousMonthMetrics.sessionCount),
                    format: { String(format: "%.0f", $0) }
                )
                MetricComparisonRow(
                    title: String(localized: "stats.volume"),
                    current: viewModel.currentMonthMetrics.totalVolume,
                    previous: viewModel.previousMonthMetrics.totalVolume,
                    format: { String(format: "%.0f kg", $0) }
                )
                MetricComparisonRow(
                    title: String(localized: "stats.avg_duration"),
                    current: viewModel.currentMonthMetrics.avgDuration,
                    previous: viewModel.previousMonthMetrics.avgDuration,
                    format: { $0.formattedHoursDuration }
                )
                HStack {
                    Text(String(localized: "stats.top_muscle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.currentMonthMetrics.topMuscle)
                        .font(.subheadline.bold())
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(16)
        }
    }

    private var comparisonHeader: some View {
        HStack {
            Text(String(localized: "stats.current_month"))
                .font(.headline)
                .frame(maxWidth: .infinity)
            Divider()
            Text(String(localized: "stats.prev_month"))
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricComparisonRow: View {
    let title: String
    let current: Double
    let previous: Double
    let format: (Double) -> String

    private var change: Double {
        guard previous > 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }

    private var isPositive: Bool { change >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text(format(current))
                    .font(.title3.bold())
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%%", abs(change)))
                }
                .font(.subheadline.bold())
                .foregroundColor(change == 0 ? .secondary : (isPositive ? .green : .red))
                Text(format(previous))
                    .font(.title3.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
