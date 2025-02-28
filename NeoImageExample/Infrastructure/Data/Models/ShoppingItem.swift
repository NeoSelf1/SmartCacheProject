import Foundation

struct ShoppingItem: Decodable, Identifiable {
    let title: String
    let link: String
    let image: String
    let lprice: String
    let hprice: String
    let mallName: String
    let productId: String
    let productType: String
    let brand: String
    let maker: String
    let category1: String
    let category2: String
    let category3: String
    let category4: String
    
    // Identifiable 프로토콜 준수를 위한 id
    var id: String { productId }
    
    // HTML 태그 제거
    var cleanTitle: String {
        return title.replacingOccurrences(of: "<b>", with: "")
                   .replacingOccurrences(of: "</b>", with: "")
    }
    
    // 최저가 정수로 변환
    var lowestPrice: Int {
        return Int(lprice) ?? 0
    }
    
    // 최고가 정수로 변환
    var highestPrice: Int {
        return Int(hprice) ?? 0
    }
    
    // 최저가 포맷팅
    var formattedPrice: String {
        let price = lowestPrice
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
    
    func toProduct() -> Product {
        return Product(
            id: productId,
            title: cleanTitle,
            price: lprice,
            productType: productType,
            brand: brand,
            description: "\(maker) \(brand)",
            categories: [category1,category2,category3],
            image: image
        )
    }
}
