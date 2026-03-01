public protocol NASAService: Actor {
    var savedPhotos: [PhotoOfTheDay] { get }
    var previousDates: [String] { get }
    nonisolated var dateBackNumberOfDays: Int { get }
    func fetchPhotoOfTheDay(at index: Int) async -> PhotoOfTheDay
}
