//
//  FavoritesView.swift
//  NeoImageExample
//
//  Created by Neoself on 2/28/25.
//


import SwiftUI
import NeoImage

struct FavoritesView: View {
    @StateObject var viewModel = FavoritesViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
//            CustomHeader(title: "My Favorites")
            
            // 카테고리 필터
//            categoryFilterSection
            
            // 찜한 상품 목록
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
//                favoriteProductsList
            }
        }
        .onAppear {
            viewModel.loadFavorites()
        }
    }
    
    // 카테고리 필터 섹션
//    private var categoryFilterSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            LazyHStack(spacing: 12) {
//                ForEach(viewModel.categories, id: \.self) { category in
//                    Button(action: {
////                        viewModel.filterByCategory(category)
//                    }) {
//                        Text(category)
//                            .font(._body1)
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 8)
//                            .background(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .fill(viewModel.selectedCategory == category ? Color.red50 : Color.gray10)
//                            )
//                            .foregroundColor(viewModel.selectedCategory == category ? .white : .gray90)
//                    }
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//        }
//    }
    
    // 찜한 상품 목록
//    private var favoriteProductsList: some View {
//        ScrollView {
//            LazyVStack(spacing: 16) {
//                ForEach(viewModel.filteredProducts) { product in
//                    NavigationLink(destination: ProductDetailView(productId: product.id)) {
//                        FavoriteProductRow(product: product) {
//                            viewModel.removeFromFavorites(product)
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .padding(16)
//        }
//    }
    
    // 찜한 상품이 없을 때 표시할 뷰
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray40)
            
            Text("No favorites yet")
                .font(._headline)
                .foregroundColor(.gray80)
            
            Text("Products you like will appear here")
                .font(._body1)
                .foregroundColor(.gray60)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: MainTabView().environment(\.selectedTab, 0)) {
                Text("Browse Products")
                    .font(._subtitle2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red50)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 찜한 상품 행 컴포넌트
struct FavoriteProductRow: View {
    let product: Product
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            NeoImage(url: URL(string:product.image))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray20)
                        .frame(width: 80, height: 80)
                }
                .fade(duration: 0.3)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(._body1)
                    .foregroundColor(.gray90)
                    .lineLimit(2)
                
                Text(String(format: "$%.2f", product.price))
                    .font(._subtitle2)
                    .foregroundColor(.red50)
                
                HStack {
                    ForEach(product.categories, id: \.self){ category in
                        CategoryLabel(text: category)
                    }
                }
            }
            
            Spacer()
            
            // 삭제 버튼
            Button(action: onRemove) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red50)
            }
            .frame(width: 44, height: 44)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// SwiftUI Environment 값 설정을 위한 확장
private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var selectedTab: Int {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

#Preview {
    FavoritesView()
}
