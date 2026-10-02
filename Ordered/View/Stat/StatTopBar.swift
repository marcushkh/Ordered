import SwiftUI
import CoreData

/// The fixed header for the Statistics experience.
struct StatTopBar: View {
    @ObservedObject var viewModel: StatViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    var body: some View {
        Group {
            if let selectedEvent = viewModel.selectedEvent {
                detailHeader(for: selectedEvent)
            } else {
                overviewHeader
            }
        }
    }

    private var overviewHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Statistic")
                    .font(.title2.bold())
                Spacer()
            }

            Picker("Range", selection: $viewModel.range) {
                ForEach(StatisticRange.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.range) { _, newRange in
                HapticFeedback.light()
                withAnimation {
                    viewModel.selectRange(newRange)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private func detailHeader(for event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    HapticFeedback.light()
                    withAnimation {
                        viewModel.clearSelectedEvent()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.color3)
                        .frame(width: 32, height: 32, alignment: .leading)
                }
                Spacer()
                Text(viewModel.periodLabel(dayPlannerVM: dayPlannerVM))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                eventBubble(event, size: 36)
                Text(event.name ?? "Event")
                    .font(.title.bold())
                    .lineLimit(1)
            }


        }
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.color1)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30
            )
        )
        .background(Color.color1.ignoresSafeArea(edges: .top))
    }

    private func eventBubble(_ event: Event, size: CGFloat) -> some View {
        Circle()
            .fill(viewModel.eventColor(event))
            .frame(width: size, height: size)
            .overlay {
                Text(event.icon ?? "💡")
                    .font(.system(size: size * 0.72))
            }
    }
}
