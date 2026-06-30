import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?
    @State private var showDayDetail = false

    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                viewToggle
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if viewModel.isWeekView {
                    weekView
                } else {
                    monthView
                }

                Divider()
                upcomingList
            }
            .navigationTitle(String(localized: "tab.calendar"))
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
        Picker(String(localized: "calendar.view"), selection: $viewModel.isWeekView) {
            Text(String(localized: "calendar.month")).tag(false)
            Text(String(localized: "calendar.week")).tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 12)
    }

    private var monthView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(viewModel.currentMonthTitle)
                    .font(.headline)
                Spacer()
                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 40)
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

    private var weekView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
            .padding(.vertical, 12)
        }
    }

    private var upcomingList: some View {
        Group {
            let upcoming = viewModel.sessions
                .filter { $0.scheduledDate >= Date().startOfDay && $0.endedAt == nil }
                .sorted { $0.scheduledDate < $1.scheduledDate }
                .prefix(5)

            if upcoming.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text(String(localized: "calendar.no_upcoming"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                List(Array(upcoming)) { session in
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.scheduledDate, style: .date)
                                .font(.subheadline.bold())
                            Text(session.notes.isEmpty ? String(localized: "session.no_notes") : session.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let hasSession: Bool
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var day: String {
        let c = Calendar.current.component(.day, from: date)
        return "\(c)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day)
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.accentColor : Color.clear)
                    .clipShape(Circle())

                Circle()
                    .fill(hasSession ? Color.accentColor : Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
                let day = Calendar.current.component(.day, from: date)
                Text("\(day)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .clipShape(Circle())
                Circle()
                    .fill(hasSession ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .buttonStyle(.plain)
    }
}
