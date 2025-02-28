import Foundation
import UIKit

public protocol CacheStrategy: Sendable {
    func shouldCacheInMemory(image: UIImage, url: URL, category: ImageCategory) async -> Bool
    func priorityForEviction(items: [(key: String, category: ImageCategory?)]) async -> [String]
}

public struct SmartCacheStrategy: CacheStrategy, Sendable {
    // MARK: - Properties

    /// 메모리 캐시에 유지할 각 카테고리의 최대 비율
    private var categoryAllocation: [ImageCategory: Double]

    // MARK: - Lifecycle

    /// 기본값으로 균등하게 분배된 비율 설정
    public init() {
        var allocation = [ImageCategory: Double]()
        let defaultValue = 1.0 / Double(ImageCategory.allCases.count)

        for category in ImageCategory.allCases {
            allocation[category] = defaultValue
        }

        categoryAllocation = allocation
    }

    // MARK: - Functions

    /// 사용자 행동에 따라 카테고리 할당 비율 업데이트
    public mutating func updateAllocationBasedOnUserBehavior() async {
        let importance = await UserBehaviorTracker.shared.calculateCategoryImportance()

        // 중요도 총합 계산 (정규화를 위함)
        let totalImportance = importance.values.reduce(0, +)

        if totalImportance > 0 {
            // 중요도 기반으로 비율 업데이트 (정규화)
            for (category, score) in importance {
                categoryAllocation[category] = score / totalImportance
            }
        }
    }

    /// 주어진 이미지가 메모리 캐시에 저장되어야 하는지 결정
    public func shouldCacheInMemory(
        image: UIImage,
        url _: URL,
        category: ImageCategory
    ) async -> Bool {
        // 메모리 캐시의 현재 카테고리 분포 확인
        let currentDistribution = await MemoryCacheMonitor.shared.getCurrentCategoryDistribution()

        // 이 카테고리의 목표 할당량
        let targetAllocation = categoryAllocation[category, default: 0.1]

        // 현재 이 카테고리가 차지하는 비율
        let currentAllocation = currentDistribution[category, default: 0]

        // 목표보다 낮으면 캐싱, 목표보다 높으면 이미지 크기에 따라 결정
        if currentAllocation < targetAllocation {
            return true
        } else {
            // 이미지 크기가 작으면 캐싱 (큰 이미지는 제한적으로)
            let imageSizeBytes = image.jpegData(compressionQuality: 0.8)?.count ?? 0
            return imageSizeBytes < 1024 * 100 // 100KB 이하인 이미지는 계속 캐싱
        }
    }

    /// 캐시 공간 확보 필요시 제거할 항목 우선순위 결정
    public func priorityForEviction(items: [(key: String, category: ImageCategory?)]) async
        -> [String] {
        let importance = await UserBehaviorTracker.shared.calculateCategoryImportance()

        // 중요도의 역순으로 정렬 (중요도가 낮은 카테고리 먼저 제거)
        return items.sorted { item1, item2 in
            let importance1 = item1.category.map { importance[$0, default: 0] } ?? 0
            let importance2 = item2.category.map { importance[$0, default: 0] } ?? 0
            return importance1 < importance2
        }.map(\.key)
    }
}
