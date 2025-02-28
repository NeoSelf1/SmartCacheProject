import Foundation

class NaverShoppingDataSource {
    private let naverAPIBaseURL = "https://openapi.naver.com/v1/search/shop.json"
    private let clientID: String
    private let clientSecret: String
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.clientID = EnvironmentVar().clientID
        self.clientSecret = EnvironmentVar().clientSecret
        self.session = session
    }
    
    func searchProducts(
        query: String,
        display: Int = 10,
        start: Int = 1,
        sort: NaverShoppingSortOption = .sim,
        filter: NaverShoppingFilter = .all,
        exclude: NaverShoppingExclude? = nil
    ) async throws -> ShoppingSearchResponse {
        guard var urlComponents = URLComponents(string: naverAPIBaseURL) else {
            throw APIError.invalidURL
        }
        
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "display", value: String(display)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        if filter != .all {
            queryItems.append(URLQueryItem(name: "filter", value: filter.rawValue))
        }
        
        if let excludeString = exclude?.toQueryString() {
            queryItems.append(URLQueryItem(name: "exclude", value: excludeString))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(clientID, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.notFound
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 400:
                    // SE01, SE02, SE03, SE04, SE06 등의 네이버 쇼핑 API 오류 처리
                    if let errorResponse = try? JSONDecoder().decode(NaverErrorResponse.self, from: data) {
                        throw APIError.serverError("\(errorResponse.errorCode): \(errorResponse.errorMessage)")
                    }
                    throw APIError.invalidRequest
                case 401:
                    throw APIError.unauthorized
                case 403:
                    throw APIError.forbidden
                case 404:
                    throw APIError.notFound
                case 429:
                    throw APIError.tooManyRequests
                case 500...599:
                    throw APIError.serverError(String(httpResponse.statusCode))
                default:
                    throw APIError.networkError
                }
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(ShoppingSearchResponse.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            print("디코딩 에러: \(error)")
            throw APIError.decodingError
        } catch {
            throw APIError.networkError
        }
    }
    
    func fetchProductDetail(productId: String) async throws -> Product? {
        // 네이버 쇼핑 API는 productId로 직접 검색하는 기능이 없어서,
        // 상품 ID로 검색하는 방식으로 구현
        let response = try await searchProducts(query: "productId:\(productId)", display: 1)
        
        return response.items.first?.toProduct()
    }
}
