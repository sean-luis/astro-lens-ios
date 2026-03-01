import Foundation
import SwiftData

@Model
final class FavoriteAPOD {
    @Attribute(.unique) var date: String
    var createdAt: Date

    init(date: String, createdAt: Date = .now) {
        self.date = date
        self.createdAt = createdAt
    }
}

@Model
final class CachedAPOD {
    @Attribute(.unique) var date: String
    var title: String
    var explanation: String
    var imageURL: String
    var imageData: Data?
    var updatedAt: Date

    init(
        date: String,
        title: String,
        explanation: String,
        imageURL: String,
        imageData: Data? = nil,
        updatedAt: Date = .now
    ) {
        self.date = date
        self.title = title
        self.explanation = explanation
        self.imageURL = imageURL
        self.imageData = imageData
        self.updatedAt = updatedAt
    }
}
