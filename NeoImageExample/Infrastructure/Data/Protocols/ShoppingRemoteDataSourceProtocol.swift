protocol ShoppingRemoteDataSourceProtocol {
    func fetchAllProducts() async throws -> ShoppingSearchResponse
    func fetchProductsByCategory(_ category: String) async throws -> ShoppingSearchResponse
    func searchProducts(query: String) async throws ->ShoppingSearchResponse
    func fetchProductDetail(id: String) async throws -> Product
}
