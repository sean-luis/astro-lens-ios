import Foundation
import NASAApi

/*public final class LandingScreenDataLoadOperation: Operation {
    public private(set) var response: PhotoOfTheDay?
    private var completionHandler: ((PhotoOfTheDay) -> Void)
    private let index: Int
    
    public func updateCompletionHandler(with completionHandler: @escaping ((PhotoOfTheDay) -> Void)) {
        self.completionHandler = completionHandler
    }
        
    public init(atIndex index: Int, withCompletion completionHandler: @escaping ((PhotoOfTheDay) -> Void)) {
        self.index = index
        self.completionHandler = completionHandler
    }
    
    public override func main() {
        if isCancelled { return }
        NASAServiceImplementation.shared.fetchPhotoOfTheDay(at: index, completionHandler: { [weak self] response in
            guard let self = self else { return }
            self.response = response
            self.completionHandler(response)
        })
    }
}*/
