import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let title: String
    let price: String
    let productType: String
    let brand: String
    let description: String
    let categories: [String]
    let image: String
}

