import Foundation
import UIKit

public struct ActionData {

    public fileprivate(set) var roomName: String?
    public fileprivate(set) var roomInfo: String?
    public fileprivate(set) var roomCapacity: Int?
    public fileprivate(set) var image: UIImage?

    public init(title: String) {
        self.roomName = title
    }

    public init(title: String, subtitle: String, capacity: Int) {
        self.init(title: title)
        self.roomInfo = subtitle
        self.roomCapacity = capacity
    }

//    public init(title: String, subtitle: String, image: UIImage) {
//        self.init(title: title, subtitle: subtitle)
//        self.image = image
//    }
//
    public init(title: String, image: UIImage) {
        self.init(title: title)
        self.image = image
    }
}
