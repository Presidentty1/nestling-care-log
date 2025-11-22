import WidgetKit
import SwiftUI

@main
struct NuzzleWidgets: WidgetBundle {
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

