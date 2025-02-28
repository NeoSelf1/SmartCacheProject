import Foundation

class NaverShoppingRemoteDataSource: ShoppingRemoteDataSourceProtocol {
    private let naverSource: NaverShoppingDataSource
    
    init() {
        self.naverSource = NaverShoppingDataSource()
    }
    
    func fetchAllProducts() async throws -> ShoppingSearchResponse {
        return try await naverSource.searchProducts(
            query: "인기상품",
            display: 20,
            sort: .sim
        )
    }
    
    func searchProducts(query: String) async throws -> ShoppingSearchResponse {
        return try await naverSource.searchProducts(
            query: query,
            display: 20,
            sort: .sim
        )
    }
    
    func fetchProductsByCategory(_ category: String) async throws -> ShoppingSearchResponse {
        return try await naverSource.searchProducts(
            query: category,
            display: 20,
            sort: .sim
        )
    }
    
    func fetchProductDetail(id: String) async throws -> Product {
        guard let item = try await naverSource.fetchProductDetail(productId: id) else {
            throw APIError.notFound
        }
        
        return item
    }
}

