import SwiftUI
import NeoImage

struct ProductDetailView: View {
    @StateObject private var viewModel: ProductDetailViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(productId: String) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: productId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 네비게이션 헤더
                navigationHeader
                
                if viewModel.isLoading {
                    ProgressView("상품 정보를 불러오는 중...")
                        .padding(.top, 50)
                } else if let product = viewModel.product {
                    // 상품 상세 정보
                    productDetailContent(product)
                } else {
                    Text("상품 정보를 불러올 수 없습니다.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alert in
            Alert(title: Text("오류"), message: Text(alert.message), dismissButton: .default(Text("확인")))
        }
    }
    
    // 네비게이션 헤더
    private var navigationHeader: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            
            Spacer()
            
            Button(action: {
                // 공유 기능 (실제로는 구현 필요)
                // ShareSheet 등을 통해 구현
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
            
            Button(action: {
                if let product = viewModel.product {
                    viewModel.toggleFavorite()
                }
            }) {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.isFavorite ? .red : .primary)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 44) // Safe area 보정
        .zIndex(1) // 이미지 위에 보이도록
    }
    
    // 상품 상세 정보 컨텐츠
    private func productDetailContent(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            productImageSection(product)
            
            VStack(alignment: .leading, spacing: 16) {
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // 가격 정보
                    priceInfoSection(product)
                }
                .padding(.horizontal, 16)
                
                Divider()
                
                // 상품 카테고리
                categoryInfoSection(product)
                
                // 상품 정보 (제조사, 브랜드)
                if !product.brand.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("상품 정보")
                            .font(.headline)
                        
                        if !product.brand.isEmpty {
                            HStack {
                                Text("브랜드")
                                    .foregroundColor(.gray)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text(product.brand)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // 유사 상품 섹션
                similarProductsSection
                
                // 하단 버튼
                bottomButtons(product)
            }
        }
    }
    
    // 상품 이미지 섹션
    private func productImageSection(_ product: Product) -> some View {
        ZStack(alignment: .bottomTrailing) {
            NeoImage(urlString: product.image)
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                        )
                }
                .fade(duration: 0.5)
                .frame(height: 300)
                .clipped()
        }
    }
    
    // 가격 정보 섹션
    private func priceInfoSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("가격")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(product.price)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("원")
                    .font(.headline)
            }
        }
    }
    
    // 카테고리 정보 섹션
    private func categoryInfoSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("카테고리")
                .font(.headline)
            
            // 카테고리 경로
            HStack {
                ForEach(product.categories, id: \.self){ category in
                    CategoryLabel(text: category)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // 유사 상품 섹션
    private var similarProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.similarProducts.isEmpty {
                Text("같은 카테고리 상품")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.similarProducts) { product in
                            NavigationLink(destination: ProductDetailView(productId: product.id)) {
                                SimilarProductCard(product: product)
                                    .frame(width: 150)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // 하단 버튼 섹션
    private func bottomButtons(_ product: Product) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.toggleFavorite()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                    
                    Text("찜하기")
                        .font(.caption)
                }
                .foregroundColor(viewModel.isFavorite ? .red : .primary)
                .frame(width: 60)
            }
        }
        .padding(16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: -2)
    }
}

// 카테고리 라벨 컴포넌트
struct CategoryLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
    }
}

// 유사 상품 카드 컴포넌트
struct SimilarProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            NeoImage(urlString: product.image)
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .fade(duration: 0.3)
                .frame(height: 150)
                .cornerRadius(8)
            
            Text(product.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text("\(product.price)원")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}
