import SwiftData
import SwiftUI

@main
struct AstroLensApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: FavoriteAPOD.self, CachedAPOD.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            APODFeedView()
                .modelContainer(container)
        }
    }
}
