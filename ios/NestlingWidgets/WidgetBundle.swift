import WidgetKit
import SwiftUI

@main
struct NestlingWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        NextNapWidget()
        NextFeedWidget()
        TodaySummaryWidget()
        
        if #available(iOS 16.1, *) {
            SleepActivityWidget()
        }
    }
}

