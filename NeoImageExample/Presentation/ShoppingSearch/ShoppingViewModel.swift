//
//  ShoppingViewModel.swift
//  NeoImageExample
//
//  Created by Neoself on 2/28/25.
//


import Foundation
import SwiftUI

@MainActor
class ShoppingViewModel: ObservableObject {
    // 검색 결과 및 상태
    @Published var products: [Product] = []
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true
    
    @Published var selectedSortOption: NaverShoppingSortOption = .sim
    @Published var recentSearches: [String] = []
    
    private var currentPage = 1
    private var totalResults = 0
    
    private let repository: ShoppingRepositoryProtocol
        
    init(repository: ShoppingRepositoryProtocol = ShoppingRepository(
        remoteDataSource: NaverShoppingRemoteDataSource(),
        localDataSource: ProductLocalDataSource()
    )) {
        self.repository = repository
        loadRecentSearches()
    }
    
    func searchProducts() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            products = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let result = try await repository.searchProducts(
                query: searchQuery,
                page: currentPage,
                sort: selectedSortOption
            )
            
            products = result.items.map{$0.toProduct()}
            totalResults = result.total
            currentPage = 1
            hasMorePages = products.count < totalResults
            
            loadRecentSearches()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadMoreProducts() async {
        guard hasMorePages, !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response = try await repository.searchProducts(
                query: searchQuery,
                page: currentPage,
                sort: selectedSortOption
            )
            
            products.append(contentsOf: response.items.map{ $0.toProduct() })
            
            hasMorePages = (products.count < totalResults) && (response.items.count > 0)
        } catch {
            handleError(error)
            currentPage -= 1  // 실패 시 페이지 번호 원상복구
        }
        
        isLoading = false
    }
    
    func changeSortOption(_ option: NaverShoppingSortOption) async {
        selectedSortOption = option
        await searchProducts()
    }
    
    func useRecentSearch(_ query: String) async {
        searchQuery = query
        await searchProducts()
    }
    
    func clearRecentSearches() {
        repository.clearRecentSearches()
        loadRecentSearches()
    }
    
    private func loadRecentSearches() {
        recentSearches = repository.getRecentSearches()
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidRequest:
                errorMessage = "검색어를 확인해주세요."
            case .unauthorized, .forbidden:
                errorMessage = "API 인증에 실패했습니다. API 키를 확인해주세요."
            case .tooManyRequests:
                errorMessage = "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
            case let .serverError(message):
                errorMessage = "서버 오류: \(message)"
            default:
                errorMessage = "검색 중 오류가 발생했습니다."
            }
        } else {
            errorMessage = "네트워크 오류가 발생했습니다."
        }
        
        print("Error: \(error.localizedDescription)")
    }
}
