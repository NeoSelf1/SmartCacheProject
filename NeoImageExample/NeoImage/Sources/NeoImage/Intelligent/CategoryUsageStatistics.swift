import Foundation

public struct CategoryUsageStatistics: Sendable {
    // MARK: - Properties

    var usageCount: [ImageCategory: Int]
    var lastAccessTime: [ImageCategory: Date]

    // MARK: - Computed Properties

    /// 각 카테고리별 사용 빈도를 백분율로 변환
    var usagePercentage: [ImageCategory: Double] {
        let total = usageCount.values.reduce(0, +)
        guard total > 0 else {
            return [:]
        }

        var percentages = [ImageCategory: Double]()
        for (category, count) in usageCount {
            percentages[category] = Double(count) / Double(total)
        }
        return percentages
    }

    /// 최근 사용 가중치 (최근 사용할수록 높은 가중치)
    var recencyWeight: [ImageCategory: Double] {
        let now = Date()
        let maxInterval: TimeInterval = 7 * 24 * 60 * 60 // 1주일을 최대 간격으로 설정

        var weights = [ImageCategory: Double]()
        for (category, date) in lastAccessTime {
            let interval = now.timeIntervalSince(date)
            let normalizedRecency = max(0, 1 - (interval / maxInterval))
            weights[category] = normalizedRecency
        }
        return weights
    }

    // MARK: - Lifecycle

    init() {
        usageCount = [:]
        lastAccessTime = [:]

        // 모든 카테고리에 대해 초기값 설정
        for category in ImageCategory.allCases {
            usageCount[category] = 0
            lastAccessTime[category] = Date(timeIntervalSince1970: 0)
        }
    }
}
