// 쇼핑 검색 응답 모델
struct ShoppingSearchResponse: Decodable {
    let lastBuildDate: String
    let total: Int
    let start: Int
    let display: Int
    let items: [ShoppingItem]
}
