import Foundation

class ShoppingRepository: ShoppingRepositoryProtocol {

    private let remoteDataSource: ShoppingRemoteDataSourceProtocol
    private let localDataSource: ProductLocalDataSourceProtocol
    private let userDefaults = UserDefaults.standard
    private let recentSearchesKey = "recentShoppingSearches"
    private let maxRecentSearches = 10
    private let itemsPerPage = 20
    
    init(
        remoteDataSource: ShoppingRemoteDataSourceProtocol = NaverShoppingRemoteDataSource(),
        localDataSource: ProductLocalDataSourceProtocol = ProductLocalDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    func searchProducts(query: String, page: Int = 1, sort: NaverShoppingSortOption = .sim) async throws -> ShoppingSearchResponse {
        let startIndex = (page - 1) * itemsPerPage + 1
        let result = try await remoteDataSource.searchProducts(
            query: query
        )
        
        // 검색 쿼리 저장
        if !query.isEmpty && !query.hasPrefix("productId:") {
            saveRecentSearch(query)
        }
        
        return result
    }
    
    func getProductDetail(productId: String) async throws -> Product? {
        return try await remoteDataSource.fetchProductDetail(id: productId)
    }
    
    func getRecentSearches() -> [String] {
        return userDefaults.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    func saveRecentSearch(_ query: String) {
        var recentSearches = getRecentSearches()
        
        // 중복 제거 (이미 있으면 삭제)
        if let index = recentSearches.firstIndex(of: query) {
            recentSearches.remove(at: index)
        }
        
        // 맨 앞에 새 검색어 추가
        recentSearches.insert(query, at: 0)
        
        // 최대 개수 유지
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        userDefaults.set(recentSearches, forKey: recentSearchesKey)
    }
    
    func clearRecentSearches() {
        userDefaults.removeObject(forKey: recentSearchesKey)
    }
    
    // 찜한 상품 관련 메서드
    func getFavoriteProducts() throws -> [Product] {
        return try localDataSource.getAllFavoriteProducts()
    }
    
    func addProductToFavorites(_ product: Product) throws {
        try localDataSource.saveFavoriteProduct(product)
    }
    
    func removeProductFromFavorites(id: String) throws {
        try localDataSource.deleteFavoriteProduct(id: id)
    }
    
    func isFavorite(productId: String) throws -> Bool {
        return try localDataSource.getFavoriteProduct(id: productId) != nil
    }
    
}
