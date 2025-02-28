import Foundation

public actor UserBehaviorTracker: Sendable {
    // MARK: - Static Properties

    public static let shared = UserBehaviorTracker()

    // MARK: - Properties

    /// 사용자의 카테고리별 사용 통계
    private var statistics = CategoryUsageStatistics()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Functions

    /// 이미지 카테고리 사용 기록
    public func recordCategoryUsage(_ category: ImageCategory) {
        statistics.usageCount[category, default: 0] += 1
        statistics.lastAccessTime[category] = Date()
    }

    /// 현재 카테고리 사용 통계 조회
    public func getCategoryStatistics() -> CategoryUsageStatistics {
        statistics
    }

    /// 각 카테고리별 중요도 점수 계산 (사용 빈도 + 최근 사용 가중치)
    public func calculateCategoryImportance() -> [ImageCategory: Double] {
        let usagePercentage = statistics.usagePercentage
        let recencyWeight = statistics.recencyWeight

        var importance = [ImageCategory: Double]()

        // 사용 빈도(70%)와 최근 사용(30%)을 조합하여 중요도 계산
        for category in ImageCategory.allCases {
            let usageScore = usagePercentage[category, default: 0] * 0.7
            let recencyScore = recencyWeight[category, default: 0] * 0.3
            importance[category] = usageScore + recencyScore
        }

        return importance
    }
}
