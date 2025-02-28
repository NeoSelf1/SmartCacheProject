//
//  ProductEntity.swift
//  NeoImageExample
//
//  Created by Neoself on 2/28/25.
//

// ProductEntity 확장
extension ProductEntity {
    func toDomain() -> Product {
        return Product(
            id: productId ?? "",
            title: title ?? "",
            price: price ?? "",
            productType: productType ?? "",
            brand: brand ?? "",
            description: productDescription ?? "",
            categories: categories ?? [],
            image: image ?? ""
        )
    }
}
