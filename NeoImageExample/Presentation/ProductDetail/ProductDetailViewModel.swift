import SwiftUI

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var product: Product
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var similarProducts: [Product] = []
    @Published var isFavorite = false
    
    private let repository: ShoppingRepositoryProtocol
    
    init(
        product:Product,
        repository: ShoppingRepositoryProtocol = ShoppingRepository()
    ) {
        self.product = product
        self.repository = repository
    }
    
    func loadProductDetail(productId: String) async {
        isLoading = true
        errorMessage = nil
        
        // 즐겨찾기 상태 체크
        checkFavoriteStatus()
        
        // 유사 상품 검색 (카테고리 기반)
        if let category = product.categories.first {
            await searchSimilarProducts(category: category)
        }
        
        isLoading = false
    }
    
    private func searchSimilarProducts(category: String) async {
        do {
            let results = try await repository.searchProducts(
                query: category,
                page: 1,
                sort: .sim
            )
            
            similarProducts = results.items.map{$0.toProduct()}
        } catch {
            print("Error loading similar products: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite() {
        do {
            if isFavorite {
                try repository.removeProductFromFavorites(id: product.id)
            } else {
                try repository.addProductToFavorites(product)
            }
            
            isFavorite.toggle()
        } catch {
            errorMessage = "찜하기 상태 변경에 실패했습니다."
            print("Error toggling favorite: \(error.localizedDescription)")
        }
    }
    
    private func checkFavoriteStatus() {
        do {
            isFavorite = try repository.isFavorite(productId: product.id)
        } catch {
            print("Error checking favorite status: \(error.localizedDescription)")
            isFavorite = false
        }
    }
}
