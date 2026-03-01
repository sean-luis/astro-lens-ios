import Foundation
import UIKit

public final actor NASAServiceImplementation: NASAService {
    public private(set) var savedPhotos: [PhotoOfTheDay] = []
    public private(set) var previousDates: [String] = []
    public let dateBackNumberOfDays = 7
    private let urlSession = URLSession.shared
    private let noContentTitle = "No photo available for this date"
    private let noContentDescription = "No content available for this date"
    private let noContentImageURL = ""
    private typealias APIResponse = (data: Data?, urlResponse: URLResponse?)
    
    public init() {}
    
    public func fetchPhotoOfTheDay(at index: Int) async -> PhotoOfTheDay {
        if !savedPhotos.isEmpty && previousDates[index] == findDateOfSavedPhoto(atIndex: index) {
            return await retrievePhotoOfTheDayFromStorage(atIndex: index)
        } else {
            return await retrievePhotoOfTheDayViaNetwork(atIndex: index)
        }
    }
    
    private func retrievePhotoOfTheDayFromStorage(atIndex index: Int) async -> PhotoOfTheDay {
        guard savedPhotos.indices.contains(index) else { return makeEmptyPhotoOfTheDay(at: index) }
        return savedPhotos[index]
    }
    
    private func retrievePhotoOfTheDayViaNetwork(atIndex index: Int) async -> PhotoOfTheDay {
        previousDates = findDates(withOffset: dateBackNumberOfDays)
        let urlString = "https://api.nasa.gov/planetary/apod?date=\(previousDates[index])&hd=true&api_key=DEMO_KEY"
        guard let url = URL(string: urlString) else { return makeEmptyPhotoOfTheDay(at: index) }
        
        return await retrievePhotoOfTheDayContent(with: url, at: index)
    }
    
    private func retrievePhotoOfTheDayContent(with url: URL, at index: Int) async -> PhotoOfTheDay {
        let request = URLRequest(url: url)
        print("Started request for \(url.absoluteString), at index: \(index)")
        
        do {
            let apiResponse = try await urlSession.data(for: request)
            return await handleResponse(using: apiResponse, at: index)
        } catch {
            return makeEmptyPhotoOfTheDay(at: index)
        }
    }
    
    private func handleResponse(using apiResponse: APIResponse, at index: Int) async -> PhotoOfTheDay {
        guard let httpResponse = apiResponse.urlResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200, let data = apiResponse.data else {
            return makeEmptyPhotoOfTheDay(at: index)
        }
        
        do {
            let response = try decodeModel(PhotoOfTheDayResponse.self, from: data)
            let photoOfTheDay = await loadImage(from: response)
            storeContent(content: photoOfTheDay)
            print("Successfully stored \(photoOfTheDay), at index: \(index)")
            return photoOfTheDay
        } catch {
            return makeEmptyPhotoOfTheDay(at: index)
        }
    }
    
    nonisolated private func decodeModel<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
    
    private func loadImage(from response: PhotoOfTheDayResponse) async -> PhotoOfTheDay {
        guard let imageURL = URL(string: response.imageURL), let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) else {
            return PhotoOfTheDay(title: response.title, date: response.date, description: response.description, image: nil, imageURL: response.imageURL)
        }
        return PhotoOfTheDay(title: response.title, date: response.date, description: response.description, image: image, imageURL: response.imageURL)
    }
    
    private func storeContent(content: PhotoOfTheDay) {
        if !(savedPhotos.contains(where: { $0.date == content.date })) {
            savedPhotos.append(content)
            
            let savedPhotosOrderedByDate = savedPhotos.sorted(by: { $0.date > $1.date })
            savedPhotos = savedPhotosOrderedByDate
        }
    }
    
    private func findDateOfSavedPhoto(atIndex index: Int) -> String {
        let savedPhotosOrderedByDate = savedPhotos.sorted(by: { $0.date > $1.date })
        guard index <= savedPhotosOrderedByDate.endIndex - 1 else { return "" }
        return savedPhotosOrderedByDate[index].date
    }
    
    private func makeEmptyPhotoOfTheDay(at index: Int) -> PhotoOfTheDay {
        PhotoOfTheDay(title: noContentTitle,
                      date: findDateOfSavedPhoto(atIndex: index),
                      description: noContentDescription,
                      image: nil,
                      imageURL: noContentImageURL)
    }
    
    private func findDates(withOffset numberOfDays: Int) -> [String] {
        let calender = Calendar.current
        var date = calender.startOfDay(for: Date())
        var days = [String]()
        for _ in 1 ... numberOfDays {
            days.append(formattedDate(calender: calender, date: date, days: days))
            date = calender.date(byAdding: .day, value: -1, to: date)!
        }
        return days
    }
    
    private func formattedDate(calender: Calendar, date: Date, days: [String]) -> String {
        let day = calender.component(.day, from: date)
        let month = calender.component(.month, from: date)
        let year = calender.component(.year, from: date)
        var monthStr = "\(month)"
        var dayStr = "\(day)"
        if month < 10 {
            monthStr = "0\(monthStr)"
        }
        if day < 10 {
            dayStr = "0\(dayStr)"
        }
        return "\(year)-\(monthStr)-\(dayStr)"
    }
}
