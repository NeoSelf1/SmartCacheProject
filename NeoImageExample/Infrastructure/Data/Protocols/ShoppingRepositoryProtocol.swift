import Foundation

protocol ShoppingRepositoryProtocol {
    func searchProducts(query: String, page: Int, sort: NaverShoppingSortOption) async throws -> ShoppingSearchResponse
    func getProductDetail(productId: String) async throws -> Product?
    func getRecentSearches() -> [String]
    func saveRecentSearch(_ query: String)
    func clearRecentSearches()
    func getFavoriteProducts() throws -> [Product]
    func addProductToFavorites(_ product: Product) throws
    func removeProductFromFavorites(id: String) throws
    func isFavorite(productId: String) throws -> Bool
}
