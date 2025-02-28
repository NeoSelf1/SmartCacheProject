import Foundation

public actor MemoryCacheMonitor: Sendable {
    // MARK: - Static Properties

    public static let shared = MemoryCacheMonitor()

    // MARK: - Properties

    /// 메모리 캐시에 있는 항목의 카테고리 정보 저장
    private var cachedItemCategories = [String: ImageCategory]()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Functions

    /// 캐시 항목에 카테고리 정보 기록
    public func recordCachedItemCategory(key: String, category: ImageCategory) {
        cachedItemCategories[key] = category
    }

    /// 캐시 항목 제거 시 카테고리 정보도 제거
    public func removeItemCategory(key: String) {
        cachedItemCategories.removeValue(forKey: key)
    }

    /// 현재 메모리 캐시의 카테고리 분포 계산
    public func getCurrentCategoryDistribution() -> [ImageCategory: Double] {
        let totalItems = cachedItemCategories.count
        guard totalItems > 0 else {
            return [:]
        }

        var distribution = [ImageCategory: Int]()

        // 각 카테고리별 항목 개수 집계
        for (_, category) in cachedItemCategories {
            distribution[category, default: 0] += 1
        }

        // 비율로 변환
        var percentages = [ImageCategory: Double]()
        for (category, count) in distribution {
            percentages[category] = Double(count) / Double(totalItems)
        }

        return percentages
    }

    /// 특정 키에 해당하는 캐시 항목의 카테고리 조회
    public func getCategoryForItem(key: String) -> ImageCategory? {
        cachedItemCategories[key]
    }

    /// 모든 캐시된 항목과 카테고리 조회
    public func getAllCachedItems() -> [(key: String, category: ImageCategory)] {
        cachedItemCategories.map { (key: $0.key, category: $0.value) }
    }
}
