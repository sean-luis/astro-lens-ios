import Foundation

protocol APODServing: Sendable {
    func metadata(for offset: Int) async throws -> APODMetadata?
    func imageData(from url: URL) async throws -> Data
}

actor APODService: APODServing {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = "DEMO_KEY") {
        self.session = session
        self.apiKey = apiKey
    }

    func metadata(for offset: Int) async throws -> APODMetadata? {
        let date = Self.dateString(offset: offset)
        let urlString = "https://api.nasa.gov/planetary/apod?date=\(date)&api_key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let apodResponse = try JSONDecoder().decode(APODResponse.self, from: data)
        guard apodResponse.mediaType == "image", let imageURL = URL(string: apodResponse.url) else {
            return nil
        }

        return APODMetadata(
            date: apodResponse.date,
            title: apodResponse.title,
            explanation: apodResponse.explanation,
            imageURL: imageURL
        )
    }

    func imageData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }

    nonisolated static func dateString(offset: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: .now)
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
