import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class APODFeedViewModel {
    private(set) var cards: [APODCard] = []
    private(set) var favoriteDates: Set<String> = []
    private(set) var isPageLoading = false

    private let modelContext: ModelContext
    private let service: APODServing
    private let imageCache: ImageMemoryCache
    private let pageSize = 8
    private var nextOffset = 0

    init(
        modelContext: ModelContext,
        service: APODServing = APODService(),
        imageCache: ImageMemoryCache = .shared
    ) {
        self.modelContext = modelContext
        self.service = service
        self.imageCache = imageCache
        loadFavoriteDates()
    }

    func loadInitialIfNeeded() async {
        guard cards.isEmpty else { return }
        await loadNextPage()
    }

    func refresh() async {
        nextOffset = 0
        cards = []
        await imageCache.clear()
        await loadNextPage()
    }

    func loadNextPageIfNeeded(currentCardID: String?) async {
        guard let currentCardID else {
            await loadNextPage()
            return
        }

        guard let index = cards.firstIndex(where: { $0.id == currentCardID }) else { return }
        let threshold = cards.index(cards.endIndex, offsetBy: -3, limitedBy: cards.startIndex) ?? cards.startIndex
        if index >= threshold {
            await loadNextPage()
        }
    }

    func retry(cardID: String) async {
        guard let card = cards.first(where: { $0.id == cardID }) else { return }
        _ = await loadCard(offset: card.offset, replacingID: cardID)
    }

    func toggleFavorite(date: String) {
        let descriptor = FetchDescriptor<FavoriteAPOD>(predicate: #Predicate { $0.date == date })
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            favoriteDates.remove(date)
        } else {
            modelContext.insert(FavoriteAPOD(date: date))
            favoriteDates.insert(date)
        }

        try? modelContext.save()
    }

    func isFavorite(date: String) -> Bool {
        favoriteDates.contains(date)
    }

    private func loadNextPage() async {
        guard !isPageLoading else { return }
        isPageLoading = true
        defer { isPageLoading = false }

        var loaded = 0
        var scanned = 0
        while loaded < pageSize && scanned < pageSize * 4 {
            let offset = nextOffset
            nextOffset += 1
            scanned += 1

            let date = APODService.dateString(offset: offset)
            cards.append(.placeholder(offset: offset, date: date))
            let wasVisible = await loadCard(offset: offset, replacingID: date)
            if wasVisible {
                loaded += 1
            }
        }
    }

    private func loadCard(offset: Int, replacingID: String) async -> Bool {
        let placeholderDate = APODService.dateString(offset: offset)

        do {
            let metadata = try await service.metadata(for: offset)
            guard let metadata else {
                removeCard(id: replacingID)
                return false
            }

            upsertCachedMetadata(metadata)

            var card = APODCard(
                id: metadata.date,
                offset: offset,
                date: metadata.date,
                title: metadata.title,
                explanation: metadata.explanation,
                imageURL: metadata.imageURL,
                image: nil,
                state: .loaded,
                isImageLoading: true
            )

            replaceCard(id: replacingID, with: card)

            if let cachedImage = await imageCache.image(for: metadata.date) {
                card.image = cachedImage
                card.isImageLoading = false
                replaceCard(id: metadata.date, with: card)
                return true
            }

            if let cached = cachedEntry(for: metadata.date),
               let data = cached.imageData,
               let image = ImageProcessing.downsampledImage(data: data) {
                await imageCache.store(image, for: metadata.date)
                card.image = image
                card.isImageLoading = false
                replaceCard(id: metadata.date, with: card)
                return true
            }

            do {
                let imageData = try await service.imageData(from: metadata.imageURL)
                guard let image = ImageProcessing.downsampledImage(data: imageData) else {
                    card.isImageLoading = false
                    replaceCard(id: metadata.date, with: card)
                    return true
                }

                await imageCache.store(image, for: metadata.date)
                upsertCachedImage(data: imageData, for: metadata.date)

                card.image = image
                card.isImageLoading = false
                replaceCard(id: metadata.date, with: card)
                return true
            } catch {
                card.isImageLoading = false
                replaceCard(id: metadata.date, with: card)
                return true
            }
        } catch {
            if let cached = cachedEntry(for: placeholderDate),
               let imageURL = URL(string: cached.imageURL) {
                var card = APODCard(
                    id: cached.date,
                    offset: offset,
                    date: cached.date,
                    title: cached.title,
                    explanation: cached.explanation,
                    imageURL: imageURL,
                    image: nil,
                    state: .loaded,
                    isImageLoading: true
                )

                if let data = cached.imageData,
                   let image = ImageProcessing.downsampledImage(data: data) {
                    card.image = image
                    card.isImageLoading = false
                }

                replaceCard(id: replacingID, with: card)
                return true
            }

            let failure = APODCard(
                id: placeholderDate,
                offset: offset,
                date: placeholderDate,
                title: "Unable to load APOD",
                explanation: "Check your network and retry this card.",
                imageURL: nil,
                image: nil,
                state: .failed("Failed to load this APOD."),
                isImageLoading: false
            )
            replaceCard(id: replacingID, with: failure)
            return true
        }
    }

    private func replaceCard(id: String, with card: APODCard) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            cards.append(card)
            return
        }

        cards[index] = card
    }

    private func removeCard(id: String) {
        cards.removeAll { $0.id == id }
    }

    private func cachedEntry(for date: String) -> CachedAPOD? {
        let descriptor = FetchDescriptor<CachedAPOD>(predicate: #Predicate { $0.date == date })
        return try? modelContext.fetch(descriptor).first
    }

    private func upsertCachedMetadata(_ metadata: APODMetadata) {
        if let cached = cachedEntry(for: metadata.date) {
            cached.title = metadata.title
            cached.explanation = metadata.explanation
            cached.imageURL = metadata.imageURL.absoluteString
            cached.updatedAt = .now
        } else {
            let cache = CachedAPOD(
                date: metadata.date,
                title: metadata.title,
                explanation: metadata.explanation,
                imageURL: metadata.imageURL.absoluteString
            )
            modelContext.insert(cache)
        }

        try? modelContext.save()
    }

    private func upsertCachedImage(data: Data, for date: String) {
        guard let cached = cachedEntry(for: date) else { return }
        cached.imageData = data
        cached.updatedAt = .now
        try? modelContext.save()
    }

    private func loadFavoriteDates() {
        let descriptor = FetchDescriptor<FavoriteAPOD>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        favoriteDates = Set(favorites.map(\.date))
    }
}
