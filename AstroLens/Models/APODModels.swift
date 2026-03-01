import Foundation
import SwiftUI
import UIKit

struct APODMetadata: Sendable, Equatable {
    let date: String
    let title: String
    let explanation: String
    let imageURL: URL
}

struct APODCard: Identifiable, Equatable {
    enum State: Equatable {
        case placeholder
        case loaded
        case failed(String)
    }

    let id: String
    let offset: Int
    var date: String
    var title: String
    var explanation: String
    var imageURL: URL?
    var image: UIImage?
    var state: State
    var isImageLoading: Bool

    static func placeholder(offset: Int, date: String) -> APODCard {
        APODCard(
            id: date,
            offset: offset,
            date: date,
            title: "Loading APOD...",
            explanation: "",
            imageURL: nil,
            image: nil,
            state: .placeholder,
            isImageLoading: false
        )
    }
}

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}
