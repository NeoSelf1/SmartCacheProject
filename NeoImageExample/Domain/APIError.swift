// 네이버 API 에러 응답 모델
struct NaverErrorResponse: Decodable {
    let errorCode: String
    let errorMessage: String
}

// API 에러 공통 정의
enum APIError: Error, Equatable {
    case invalidURL
    case invalidRequest
    case decodingError
    
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests
    
    case networkError
    case serverError(String)
    case unknown
}
