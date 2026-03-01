nonisolated public struct PhotoOfTheDayResponse: Codable {
    var title: String
    var date: String
    var description: String
    var imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case date
        case description = "explanation"
        case imageURL = "url"
    }
}
