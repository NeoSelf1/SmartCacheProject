import CoreML
import Foundation
import UIKit
import Vision

public enum ImageCategory: String, CaseIterable, Sendable {
    case food
    case landscape
    case person
    case animal
    case product
    case text
    case art
    case vehicle
    case building
    case unknown

    // MARK: - Static Functions

    static func fromClassificationIdentifier(_ identifier: String) -> ImageCategory {
        if identifier.contains("food") || identifier.contains("dish") || identifier
            .contains("fruit") {
            return .food
        } else if identifier.contains("landscape") || identifier
            .contains("mountain") || identifier.contains("beach") {
            return .landscape
        } else if identifier.contains("person") || identifier.contains("human") || identifier
            .contains("face") {
            return .person
        } else if identifier.contains("animal") || identifier.contains("dog") || identifier
            .contains("cat") {
            return .animal
        } else if identifier.contains("product") || identifier.contains("device") {
            return .product
        } else if identifier.contains("text") || identifier.contains("document") {
            return .text
        } else if identifier.contains("art") || identifier.contains("painting") {
            return .art
        } else if identifier.contains("car") || identifier.contains("vehicle") || identifier
            .contains("airplane") {
            return .vehicle
        } else if identifier.contains("building") || identifier.contains("architecture") {
            return .building
        } else {
            return .unknown
        }
    }
}
