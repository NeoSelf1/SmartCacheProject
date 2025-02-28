import Foundation

import SwiftUI


@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: ShoppingRepositoryProtocol
    
    init(repository: ShoppingRepositoryProtocol = ShoppingRepository()) {
        self.repository = repository
    }
    
    func loadFavorites() {
        isLoading = true
        
        do {
            favoriteProducts = try repository.getFavoriteProducts()
            isLoading = false
        } catch {
            errorMessage = "찜 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
            isLoading = false
            print("Error loading favorites: \(error)")
        }
    }
    
    func removeFavorites(at indexSet: IndexSet) {
        let productsToRemove = indexSet.map { favoriteProducts[$0] }
        
        for product in productsToRemove {
            do {
                try repository.removeProductFromFavorites(id: product.id)
            } catch {
                errorMessage = "상품을 삭제하는데 실패했습니다: \(error.localizedDescription)"
                print("Error removing product from favorites: \(error)")
            }
        }
        
        indexSet.forEach { favoriteProducts.remove(at: $0) }
    }
}
