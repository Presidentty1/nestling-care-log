import SwiftUI

/// In-app help center for self-service support
/// Research: 81% try self-service first
/// Goal: Deflect 20-50% of support tickets
struct HelpCenterView: View {
    @StateObject private var helpService = HelpCenterService.shared
    @State private var searchText = ""
    @State private var selectedArticle: HelpArticle?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Search bar
                    SearchBar(text: $searchText, placeholder: "Search for help...")
                        .padding(.horizontal)
                    
                    // Search results (if searching)
                    if !searchText.isEmpty {
                        searchResultsSection
                    } else {
                        // Categories and recent articles
                        categoriesSection
                        
                        if !helpService.recentlyViewed.isEmpty {
                            recentlyViewedSection
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedArticle) { article in
                HelpArticleDetailView(article: article)
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                helpService.searchResults = helpService.searchArticles(query: newValue)
            }
        }
    }
    
    // MARK: - Search Results
    
    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results for '\(searchText)'")
                .font(.headline)
                .padding(.horizontal)
            
            if helpService.searchResults.isEmpty {
                Text("No articles found. Try different keywords or contact support.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(helpService.searchResults) { article in
                    ArticleRow(article: article) {
                        selectedArticle = article
                        helpService.trackArticleView(article)
                    }
                }
            }
        }
    }
    
    // MARK: - Categories
    
    @ViewBuilder
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by topic")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(HelpCategory.allCases) { category in
                    CategoryCard(category: category) {
                        // Navigate to category articles
                        // For now, just search by category
                        searchText = category.displayName
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recently Viewed
    
    @ViewBuilder
    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently viewed")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(helpService.recentlyViewed.prefix(5)) { article in
                ArticleRow(article: article) {
                    selectedArticle = article
                    helpService.trackArticleView(article)
                }
            }
        }
    }
}

/// Category card for help center
struct CategoryCard: View {
    let category: HelpCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Article row for list display
struct ArticleRow: View {
    let article: HelpArticle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: article.category.icon)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(article.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

/// Search bar component
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

/// Help article detail view
struct HelpArticleDetailView: View {
    let article: HelpArticle
    @State private var wasHelpful: Bool?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category badge
                    HStack {
                        Image(systemName: article.category.icon)
                            .font(.caption)
                        Text(article.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                    
                    // Title
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Content
                    Text(article.content)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // Video (if available)
                    if article.videoUrl != nil {
                        Button("Watch video tutorial") {
                            // Play video
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                    
                    Divider()
                    
                    // Was this helpful?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Was this helpful?")
                            .font(.headline)
                        
                        if wasHelpful == nil {
                            HStack(spacing: 12) {
                                Button(action: {
                                    wasHelpful = true
                                    HelpCenterService.shared.trackArticleHelpful(article, wasHelpful: true)
                                }) {
                                    HStack {
                                        Image(systemName: "hand.thumbsup.fill")
                                        Text("Yes")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    wasHelpful = false
                                    HelpCenterService.shared.trackArticleHelpful(article, wasHelpful: false)
                                }) {
                                    HStack {
                                        Image(systemName: "hand.thumbsdown.fill")
                                        Text("No")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                                }
                            }
                        } else if wasHelpful == true {
                            Text("✓ Glad we could help!")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sorry this didn't help.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button("Contact support") {
                                    // Open support contact
                                }
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    // Related articles
                    if !article.relatedArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related articles")
                                .font(.headline)
                            
                            ForEach(article.relatedArticles, id: \.self) { relatedId in
                                if let relatedArticle = HelpCenterService.shared.getArticle(id: relatedId) {
                                    Button(action: {
                                        // Navigate to related article
                                    }) {
                                        HStack {
                                            Text(relatedArticle.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Still need help?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Still need help?")
                            .font(.headline)
                        
                        Button(action: {
                            // Open contact support
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                            .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Contextual help button that appears in forms
struct ContextualHelpButton: View {
    let context: HelpContext
    @State private var showHelp = false
    
    var body: some View {
        Button(action: { showHelp = true }) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.accentColor)
        }
        .accessibilityLabel("Get help")
        .sheet(isPresented: $showHelp) {
            if let article = HelpCenterService.shared.getContextualHelp(for: context) {
                HelpArticleDetailView(article: article)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HelpCenterView()
}

#Preview("Article Detail") {
    HelpArticleDetailView(
        article: HelpArticle(
            id: "how-to-log-feed",
            title: "How do I log a feed?",
            content: """
            Logging a feed is easy:
            
            1. Tap the "Feed" button on the Home screen
            2. Enter the amount (if bottle)
            3. Select the time (defaults to now)
            4. Tap "Save"
            
            That's it! The feed is logged and syncs automatically.
            """,
            category: .logging,
            searchKeywords: ["log", "feed", "bottle"],
            videoUrl: nil,
            relatedArticles: ["how-to-log-sleep"]
        )
    )
}
