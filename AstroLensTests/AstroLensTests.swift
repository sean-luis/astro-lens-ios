import SwiftData
import XCTest
@testable import AstroLens

nonisolated final class AstroLensTests: XCTestCase {
    @MainActor
    func testInitialLoadBuildsCardsFromService() async throws {
        let (container, context) = try makeInMemoryModelContext()
        _ = container

        let service = MockAPODService(
            metadataByOffset: [
                0: APODMetadata(date: "2026-03-01", title: "T1", explanation: "E1", imageURL: URL(string: "https://example.com/1.jpg")!),
                1: APODMetadata(date: "2026-02-28", title: "T2", explanation: "E2", imageURL: URL(string: "https://example.com/2.jpg")!)
            ],
            imageData: Data()
        )

        let viewModel = APODFeedViewModel(modelContext: context, service: service, imageCache: ImageMemoryCache())
        await viewModel.loadInitialIfNeeded()

        XCTAssertFalse(viewModel.cards.isEmpty)
        XCTAssertEqual(viewModel.cards.first?.title, "T1")
    }

    @MainActor
    func testRetryReplacesFailedCard() async throws {
        let (_, context) = try makeInMemoryModelContext()
        let service = FlakyAPODService(
            failOnceOffset: 0,
            successMetadata: APODMetadata(
                date: "2026-03-01",
                title: "Recovered",
                explanation: "Recovered explanation",
                imageURL: URL(string: "https://example.com/recovered.jpg")!
            ),
            imageData: Data()
        )

        let viewModel = APODFeedViewModel(modelContext: context, service: service, imageCache: ImageMemoryCache())
        await viewModel.loadInitialIfNeeded()

        let firstID = try XCTUnwrap(viewModel.cards.first?.id)
        await viewModel.retry(cardID: firstID)

        XCTAssertEqual(viewModel.cards.first?.title, "Recovered")
    }

    @MainActor
    func testToggleFavoritePersistsInSwiftData() async throws {
        let (_, context) = try makeInMemoryModelContext()
        let viewModel = APODFeedViewModel(modelContext: context, service: MockAPODService(metadataByOffset: [:], imageData: Data()), imageCache: ImageMemoryCache())

        XCTAssertFalse(viewModel.isFavorite(date: "2026-03-01"))
        viewModel.toggleFavorite(date: "2026-03-01")
        XCTAssertTrue(viewModel.isFavorite(date: "2026-03-01"))
        viewModel.toggleFavorite(date: "2026-03-01")
        XCTAssertFalse(viewModel.isFavorite(date: "2026-03-01"))
    }

    private func makeInMemoryModelContext() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FavoriteAPOD.self, CachedAPOD.self, configurations: config)
        return (container, ModelContext(container))
    }
}

private actor MockAPODService: APODServing {
    let metadataByOffset: [Int: APODMetadata]
    let imageData: Data

    init(metadataByOffset: [Int: APODMetadata], imageData: Data) {
        self.metadataByOffset = metadataByOffset
        self.imageData = imageData
    }

    func metadata(for offset: Int) async throws -> APODMetadata? {
        metadataByOffset[offset]
    }

    func imageData(from url: URL) async throws -> Data {
        imageData
    }
}

private actor FlakyAPODService: APODServing {
    let failOnceOffset: Int
    let successMetadata: APODMetadata
    let imageData: Data
    var seenOffsets: Set<Int> = []

    init(failOnceOffset: Int, successMetadata: APODMetadata, imageData: Data) {
        self.failOnceOffset = failOnceOffset
        self.successMetadata = successMetadata
        self.imageData = imageData
    }

    func metadata(for offset: Int) async throws -> APODMetadata? {
        if offset == failOnceOffset, !seenOffsets.contains(offset) {
            seenOffsets.insert(offset)
            throw URLError(.notConnectedToInternet)
        }
        return successMetadata
    }

    func imageData(from url: URL) async throws -> Data {
        imageData
    }
}
