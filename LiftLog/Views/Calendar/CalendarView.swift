import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?
    @State private var showDayDetail = false

    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                VStack(spacing: 0) {
                    viewToggle
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    if viewModel.isWeekView {
                        weekView
                    } else {
                        monthView
                    }

                    upcomingList
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
            .sheet(isPresented: $showDayDetail) {
                if let date = selectedDate {
                    DayDetailView(date: date, viewModel: viewModel)
                }
            }
        }
    }

    private var viewToggle: some View {
        HStack(spacing: 0) {
            ForEach(["Month", "Week"], id: \.self) { label in
                let isWeek = label == "Week"
                let isActive = viewModel.isWeekView == isWeek
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isWeekView = isWeek
                    }
                } label: {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isActive ? .black : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isActive ? Color.brand : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.divider, lineWidth: 1))
        .padding(.bottom, 8)
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brand)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .clipShape(Circle())
                }
                Spacer()
                Text(viewModel.currentMonthTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brand)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            // Day grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }
                ForEach(viewModel.daysInCurrentMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        hasSession: viewModel.hasSession(on: date),
                        isSelected: selectedDate?.isSameDay(as: date) ?? false,
                        isToday: date.isToday
                    ) {
                        selectedDate = date
                        showDayDetail = true
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Week View

    private var weekView: some View {
        VStack(spacing: 0) {
            // Week navigation header
            HStack {
                Button {
                    withAnimation {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brand)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .clipShape(Circle())
                }
                Spacer()
                Text(weekRangeTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button {
                    withAnimation {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brand)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Day strip
            HStack(spacing: 8) {
                ForEach(viewModel.weekDays, id: \.self) { date in
                    WeekDayCell(
                        date: date,
                        hasSession: viewModel.hasSession(on: date),
                        isSelected: selectedDate?.isSameDay(as: date) ?? false,
                        isToday: date.isToday
                    ) {
                        selectedDate = date
                        showDayDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private var weekRangeTitle: String {
        let days = viewModel.weekDays
        guard let first = days.first, let last = days.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    // MARK: - Upcoming

    private var upcomingList: some View {
        let upcoming = viewModel.sessions
            .filter { $0.scheduledDate >= Date().startOfDay && $0.endedAt == nil }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .prefix(6)

        return VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
                .padding(.bottom, 16)

            if upcoming.isEmpty {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.surface)
                            .frame(width: 60, height: 60)
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 26))
                            .foregroundColor(.textSecondary)
                    }
                    Text("No upcoming sessions")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Text("Tap any day to plan a workout")
                        .font(.caption)
                        .foregroundColor(.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Upcoming")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .tracking(0.8)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    VStack(spacing: 8) {
                        ForEach(Array(upcoming)) { session in
                            UpcomingSessionRow(session: session)
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    selectedDate = session.scheduledDate
                                    showDayDetail = true
                                }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Row

struct UpcomingSessionRow: View {
    let session: Session

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date().startOfDay, to: session.scheduledDate.startOfDay).day ?? 0
    }

    private var daysLabel: String {
        switch daysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(daysUntil) days"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brand)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.notes.isEmpty ? "Workout" : session.notes)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(session.scheduledDate, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(daysLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(daysUntil == 0 ? .brand : .textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((daysUntil == 0 ? Color.brand : Color.surface).opacity(daysUntil == 0 ? 0.15 : 1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.divider, lineWidth: daysUntil == 0 ? 0 : 1))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
    }
}

// MARK: - Month Day Cell

struct CalendarDayCell: View {
    let date: Date
    let hasSession: Bool
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var day: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.brand).frame(width: 34, height: 34)
                    } else if isToday {
                        Circle().stroke(Color.brand, lineWidth: 1.5).frame(width: 34, height: 34)
                    }
                    Text(day)
                        .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .black : (isToday ? .brand : .textPrimary))
                }
                .frame(width: 34, height: 34)

                Circle()
                    .fill(hasSession ? (isSelected ? Color.black.opacity(0.5) : Color.brand) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week Day Cell

struct WeekDayCell: View {
    let date: Date
    let hasSession: Bool
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(date.weekdaySymbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .brand : .textSecondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brand : (isToday ? Color.brand.opacity(0.15) : Color.surface))
                        .frame(width: 40, height: 40)
                    if isToday && !isSelected {
                        Circle()
                            .stroke(Color.brand, lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                    }
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .black : (isToday ? .brand : .textPrimary))
                }

                Circle()
                    .fill(hasSession ? Color.brand : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
