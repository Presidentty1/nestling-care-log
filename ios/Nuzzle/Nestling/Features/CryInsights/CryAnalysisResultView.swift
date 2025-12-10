import SwiftUI

/// View displaying cry analysis results
struct CryAnalysisResultView: View {
    let result: CryAnalysisResult
    let onFeedback: (Bool) -> Void
    let onClose: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // Category card
                CardView(variant: .elevated) {
                    VStack(spacing: .spacingMD) {
                        // Icon and category
                        HStack(spacing: .spacingMD) {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: result.category.icon)
                                        .font(.title)
                                        .foregroundColor(categoryColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.category.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)
                                
                                HStack(spacing: 4) {
                                    confidenceBars(confidence: result.confidence)
                                    Text(ConfidenceLevel.from(value: result.confidence).displayName)
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Reasoning
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Analysis")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            Text(result.reasoning)
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Suggestions
                        if !result.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: .spacingSM) {
                                Text("Suggestions")
                                    .font(.headline)
                                    .foregroundColor(.foreground)
                                
                                ForEach(result.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: .spacingSM) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.primary)
                                            .padding(.top, 6)
                                        
                                        Text(suggestion)
                                            .font(.body)
                                            .foregroundColor(.mutedForeground)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Context info
                        if let context = result.contextInfo {
                            VStack(alignment: .leading, spacing: .spacingSM) {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundColor(.foreground)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if let lastFeed = context.lastFeed {
                                        contextRow(icon: "fork.knife", label: "Last feed", value: lastFeed)
                                    }
                                    if let lastNap = context.lastNap {
                                        contextRow(icon: "moon.zzz.fill", label: "Last nap", value: lastNap)
                                    }
                                    if let lastDiaper = context.lastDiaper {
                                        contextRow(icon: "drop.fill", label: "Last diaper", value: lastDiaper)
                                    }
                                }
                                .padding(.spacingSM)
                                .background(Color.surface)
                                .cornerRadius(.radiusSM)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.spacingMD)
                }
                
                // Feedback
                CardView(variant: .default) {
                    VStack(spacing: .spacingMD) {
                        Text("Was this helpful?")
                            .font(.headline)
                            .foregroundColor(.foreground)
                        
                        HStack(spacing: .spacingMD) {
                            SecondaryButton("👍 Yes", action: {
                                Haptics.success()
                                onFeedback(true)
                            })
                            
                            SecondaryButton("👎 Not really", action: {
                                Haptics.light()
                                onFeedback(false)
                            })
                        }
                    }
                    .padding(.spacingMD)
                }
                
                // Medical disclaimer
                MedicalDisclaimer(
                    message: "This is AI-powered guidance only, not medical advice. Contact your pediatrician if you have concerns about your baby's health."
                )
                
                // Close button
                PrimaryButton("Done") {
                    Haptics.light()
                    onClose()
                }
                .padding(.horizontal, .spacingMD)
            }
            .padding(.spacingMD)
        }
        .navigationTitle("Cry Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.background)
    }
    
    private var categoryColor: Color {
        switch result.category {
        case .hungry: return .eventFeed
        case .tired: return .eventSleep
        case .discomfort: return .warning
        case .pain: return .destructive
        case .unsure: return .mutedForeground
        }
    }
    
    @ViewBuilder
    private func contextRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.mutedForeground)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.foreground)
        }
    }
    
    @ViewBuilder
    private func confidenceBars(confidence: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(confidence * 3) ? categoryColor : Color.mutedForeground.opacity(0.2))
                    .frame(width: 12, height: 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CryAnalysisResultView(
            result: CryAnalysisResult(
                category: .hungry,
                confidence: 0.75,
                reasoning: "Based on the time since the last feed and typical hunger patterns for this age",
                suggestions: [
                    "Offer a feed - even if it's been less than 2 hours",
                    "Check for hunger cues like rooting or sucking on hands"
                ],
                contextInfo: CryAnalysisResult.ContextInfo(
                    lastFeed: "2 hours ago",
                    lastNap: "45 minutes",
                    lastDiaper: "1 hour ago"
                )
            ),
            onFeedback: { _ in },
            onClose: {}
        )
    }
}

