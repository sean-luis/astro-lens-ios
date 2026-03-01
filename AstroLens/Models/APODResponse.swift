import Foundation

nonisolated struct APODResponse: Decodable, Sendable {
    let date: String
    let title: String
    let explanation: String
    let mediaType: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case date
        case title
        case explanation
        case mediaType = "media_type"
        case url
    }
}
