import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
                .widgetURL(tapURL(context))
                .activityBackgroundTint(LockScreenPalette.surface)
                .activitySystemActionForegroundColor(LockScreenPalette.accent)
        } dynamicIsland: { context in
            // Minimal layout required by the system; no buttons.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.state.title).font(.headline).lineLimit(1)
                        Text(context.state.listName)
                            .font(.subheadline)
                            .foregroundStyle(LockScreenPalette.textSecondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerClockText(state: context.state)
                        .foregroundStyle(LockScreenPalette.accent)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(LockScreenPalette.accent)
            } compactTrailing: {
                TimerClockText(state: context.state)
                    .frame(width: 56)
                    .foregroundStyle(LockScreenPalette.accent)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(LockScreenPalette.accent)
            }
            .widgetURL(tapURL(context))
        }
    }

    private func tapURL(_ context: ActivityViewContext<TimerActivityAttributes>) -> URL {
        LockScreenContract.tapURL(
            targetType: context.attributes.targetType,
            targetId: context.attributes.targetId
        )
    }
}
