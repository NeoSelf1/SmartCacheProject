protocol ProductLocalDataSourceProtocol {
    func getAllFavoriteProducts() throws -> [Product]
    func getFavoriteProduct(id: String) throws -> Product?
    func saveFavoriteProduct(_ product: Product) throws
    func deleteFavoriteProduct(id: String) throws
}
