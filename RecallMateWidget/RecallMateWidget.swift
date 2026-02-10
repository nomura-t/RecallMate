import WidgetKit
import SwiftUI

struct RecallMateWidget: Widget {
    let kind: String = "RecallMateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecallMateWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                RecallMateWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RecallMateWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("RecallMate")
        .description("ストリークと復習状況を確認")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
