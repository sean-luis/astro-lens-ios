import SwiftData
import SwiftUI

struct APODFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: APODFeedViewModel?
    @State private var sharePayload: SharePayload?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel?.cards ?? []) { card in
                        APODCardView(
                            card: card,
                            isFavorite: viewModel?.isFavorite(date: card.date) ?? false,
                            onToggleFavorite: {
                                viewModel?.toggleFavorite(date: card.date)
                            },
                            onRetry: {
                                Task { await viewModel?.retry(cardID: card.id) }
                            },
                            onShare: {
                                sharePayload = makeSharePayload(for: card)
                            }
                        )
                        .task {
                            await viewModel?.loadNextPageIfNeeded(currentCardID: card.id)
                        }
                        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                    }

                    if viewModel?.isPageLoading == true {
                        ProgressView("Loading more APODs...")
                            .padding(.vertical, 24)
                            .tint(.indigo)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(LinearGradient(colors: [Color.white, Color(red: 0.96, green: 0.98, blue: 1.0)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("AstroLens")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel == nil {
                    viewModel = APODFeedViewModel(modelContext: modelContext)
                }
                await viewModel?.loadInitialIfNeeded()
            }
            .refreshable {
                await viewModel?.refresh()
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: payload.items)
            }
        }
    }

    private func makeSharePayload(for card: APODCard) -> SharePayload {
        var items: [Any] = []
        if let image = card.image {
            items.append(image)
        }

        let body = """
        Astronomy Picture of the Day

        Date: \(card.date)
        Title: \(card.title)

        \(card.explanation)

        Source: \(card.imageURL?.absoluteString ?? "Unavailable")
        """
        items.append(body)
        if let url = card.imageURL {
            items.append(url)
        }

        return SharePayload(items: items)
    }
}
