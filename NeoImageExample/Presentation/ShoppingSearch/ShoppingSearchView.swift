//
//  ShoppingSearchView.swift
//  NeoImageExample
//
//  Created by Neoself on 2/28/25.
//


import SwiftUI
import NeoImage

struct ShoppingSearchView: View {
    @StateObject var viewModel = ShoppingViewModel()
    // 검색 시 키보드가 사라지도록 FocusState 사용
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 검색 헤더
                searchHeader
                
                // 정렬 옵션
                sortOptionsBar
                
                // 검색 결과 또는 최근 검색어
                if viewModel.searchQuery.isEmpty {
                    recentSearchesView
                } else if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("검색 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.products.isEmpty {
                    emptyResultView
                } else {
                    searchResultsList
                }
            }
            .navigationBarHidden(true)
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { alert in
                Alert(title: Text("오류"), message: Text(alert.message), dismissButton: .default(Text("확인")))
            }
        }
    }
    
    // 검색 헤더
    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("쇼핑 검색")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("상품명, 브랜드, 카테고리 검색", text: $viewModel.searchQuery)
                    .focused($isSearchFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        isSearchFocused = false
                        Task {
                            await viewModel.searchProducts()
                        }
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // 정렬 옵션 바
    private var sortOptionsBar: some View {
        HStack(spacing: 16) {
            Text("정렬:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: {
                Task {
                    await viewModel.changeSortOption(.sim)
                }
            }) {
                Text("정확도순")
                    .font(.subheadline)
                    .foregroundColor(viewModel.selectedSortOption == .sim ? .blue : .gray)
                    .underline(viewModel.selectedSortOption == .sim)
            }
            
            Button(action: {
                Task {
                    await viewModel.changeSortOption(.date)
                }
            }) {
                Text("날짜순")
                    .font(.subheadline)
                    .foregroundColor(viewModel.selectedSortOption == .date ? .blue : .gray)
                    .underline(viewModel.selectedSortOption == .date)
            }
            
            Button(action: {
                Task {
                    await viewModel.changeSortOption(.asc)
                }
            }) {
                Text("가격↑")
                    .font(.subheadline)
                    .foregroundColor(viewModel.selectedSortOption == .asc ? .blue : .gray)
                    .underline(viewModel.selectedSortOption == .asc)
            }
            
            Button(action: {
                Task {
                    await viewModel.changeSortOption(.dsc)
                }
            }) {
                Text("가격↓")
                    .font(.subheadline)
                    .foregroundColor(viewModel.selectedSortOption == .dsc ? .blue : .gray)
                    .underline(viewModel.selectedSortOption == .dsc)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    // 최근 검색어 뷰
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("최근 검색어")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.recentSearches.isEmpty {
                    Button(action: {
                        viewModel.clearRecentSearches()
                    }) {
                        Text("모두 지우기")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if viewModel.recentSearches.isEmpty {
                Text("최근 검색 내역이 없습니다.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.recentSearches, id: \.self) { query in
                            Button(action: {
                                Task {
                                    await viewModel.useRecentSearch(query)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                    
                                    Text(query)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // 검색 결과 없음 뷰
    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("검색 결과가 없습니다.")
                .font(.headline)
            
            Text("다른 검색어로 시도해 보세요.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 검색 결과 리스트
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.products) { product in
                NavigationLink(destination: ProductDetailView(productId: product.id)) {
                    ProductRow(product: product)
                }
                .onAppear {
                    if product.id == viewModel.products.last?.id && viewModel.hasMorePages {
                        Task {
                            await viewModel.loadMoreProducts()
                        }
                    }
                }
            }
            
            if viewModel.isLoading && !viewModel.products.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// 알림 아이템
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// 상품 행 컴포넌트
struct ProductRow: View {
    let product: Product
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 상품 이미지
            NeoImage(urlString: product.image)
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .fade(duration: 0.3)
                .frame(width: 100, height: 100)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if !product.brand.isEmpty {
                    Text(product.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(product.price)원")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}
