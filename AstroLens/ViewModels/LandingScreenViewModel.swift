import Foundation
import UIKit
import NASAApi

@Observable
class LandingScreenViewModel {
    let defaultImage = UIImage(named: "nasaDefault") ?? UIImage()
    var photos: [IndexPath: PhotoOfTheDay] = [:]
    
    private let service: NASAService
    
    init(service: NASAService) {
        self.service = service
    }
    
    var numberOfPhotosToRetrieve: Int {
        service.dateBackNumberOfDays
    }
    
    var savedPhotos: [PhotoOfTheDay] {
        get async {
            await service.savedPhotos
        }
    }
    
    var previousDates: [String] {
        get async {
            await service.previousDates
        }
    }
    
    @MainActor
    func fetchAllPhotos(indexPaths: [IndexPath]) async {
        await withTaskGroup(of: (indexPath: IndexPath, photoOfTheDay: PhotoOfTheDay).self) { group in
            for indexPath in indexPaths {
                group.addTask {
                    let photoOfTheDay = await self.service.fetchPhotoOfTheDay(at: indexPath.section)
                    return (indexPath, photoOfTheDay)
                }
            }

            for await photoOfTheDay in group {
                photos[photoOfTheDay.indexPath] = photoOfTheDay.photoOfTheDay
            }
        }
    }
    
    @MainActor
    func fetchPhotoOfTheDay(at indexPath: IndexPath) async -> PhotoOfTheDay {
        let photoOfTheDay = await self.service.fetchPhotoOfTheDay(at: indexPath.section)
        photos[indexPath] = photoOfTheDay
        return photoOfTheDay
    }
}
