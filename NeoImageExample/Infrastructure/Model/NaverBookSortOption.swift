
// 네이버 쇼핑 검색 정렬 옵션
enum NaverShoppingSortOption: String {
    case sim = "sim"   // 정확도순 (기본값)
    case date = "date" // 날짜순
    case asc = "asc"   // 가격 오름차순
    case dsc = "dsc"   // 가격 내림차순
}

// 네이버 쇼핑 필터 옵션
enum NaverShoppingFilter: String {
    case all = ""         // 모든 상품 (기본값)
    case naverpay = "naverpay" // 네이버페이 연동 상품
}

// 네이버 쇼핑 제외 옵션
struct NaverShoppingExclude {
    var used = false    // 중고 제외
    var rental = false  // 렌탈 제외
    var cbshop = false  // 해외직구 제외
    
    func toQueryString() -> String? {
        var options: [String] = []
        
        if used { options.append("used") }
        if rental { options.append("rental") }
        if cbshop { options.append("cbshop") }
        
        if options.isEmpty {
            return nil
        }
        
        return options.joined(separator: ":")
    }
}
