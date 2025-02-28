import Foundation
import CoreData

class ProductLocalDataSource: ProductLocalDataSourceProtocol {
    private let coreDataStack = CoreDataStack.shared
    
    func getAllFavoriteProducts() throws -> [Product] {
        var favoriteProducts: [Product] = []
        
        try coreDataStack.performInTransaction {
            let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
            
            let entities = try coreDataStack.context.fetch(fetchRequest)
            favoriteProducts = entities.map { $0.toDomain() }
        }
        
        return favoriteProducts
    }
    
    func getFavoriteProduct(id: String) throws -> Product? {
        var favoriteProduct: Product?
        
        try coreDataStack.performInTransaction {
            let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            if let entity = try coreDataStack.context.fetch(fetchRequest).first {
                favoriteProduct = entity.toDomain()
            }
        }
        
        return favoriteProduct
    }
    
    func saveFavoriteProduct(_ product: Product) throws {
        try coreDataStack.performInTransaction {
            // 이미 존재하는지 확인
            let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", product.id)
            fetchRequest.fetchLimit = 1
            
            let existingEntity = try coreDataStack.context.fetch(fetchRequest).first
            
            // 존재하면 업데이트, 없으면 새로 생성
            let entity = existingEntity ?? ProductEntity(context: coreDataStack.context)
            entity.productId = product.id
            entity.title = product.title
            entity.productDescription = product.description
            entity.image = product.image
            entity.price = product.price
            entity.categories = product.categories
            entity.lastUpdated = Date()
        }
    }
    
    func deleteFavoriteProduct(id: String) throws {
        try coreDataStack.performInTransaction {
            let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let entities = try coreDataStack.context.fetch(fetchRequest)
            for entity in entities {
                coreDataStack.context.delete(entity)
            }
        }
    }
}

