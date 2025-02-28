//
//  SmartMemoryStorage.swift
//  NeoImage
//
//  Created by Neoself on 2/26/25.
//

import Foundation
import UIKit

public actor SmartMemoryStorage {
    // MARK: - Properties

    private let cache = NSCache<NSString, NSData>()
    private let strategy: SmartCacheStrategy
    private let totalCostLimit: Int

    // MARK: - Lifecycle

    init(totalCostLimit: Int, strategy: SmartCacheStrategy = SmartCacheStrategy()) {
        self.totalCostLimit = totalCostLimit
        self.strategy = strategy
        cache.totalCostLimit = totalCostLimit
    }

    // MARK: - Functions

    /// 이미지 데이터와 카테고리 정보를 함께 저장
    func store(
        value: Data,
        forKey key: String,
        category: ImageCategory? = nil,
        expiration _: StorageExpiration?
    ) async {
        // 스마트 캐싱 결정 (카테고리가 있는 경우)
        if let category,
           let image = UIImage(data: value),
           let url = URL(string: key) {
            let shouldCache = await strategy.shouldCacheInMemory(
                image: image,
                url: url,
                category: category
            )

            if !shouldCache {
                // 캐싱하지 않기로 결정된 경우
                return
            }

            // 카테고리 정보 기록
            await MemoryCacheMonitor.shared.recordCachedItemCategory(key: key, category: category)
        }

        // NSCache에 저장
        cache.setObject(value as NSData, forKey: key as NSString)
    }

    /// 캐시에서 데이터 조회
    func value(forKey key: String) -> Data? {
        if let data = cache.object(forKey: key as NSString) as Data? {
            // 카테고리가 있다면 사용 기록 업데이트
            Task {
                if let category = await MemoryCacheMonitor.shared.getCategoryForItem(key: key) {
                    await UserBehaviorTracker.shared.recordCategoryUsage(category)
                }
            }
            return data
        }
        return nil
    }

    /// 특정 키의 데이터 제거
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        Task {
            await MemoryCacheMonitor.shared.removeItemCategory(key: key)
        }
    }

    /// 모든 데이터 제거
    func removeAll() {
        cache.removeAllObjects()
        Task {
            for (key, _) in await MemoryCacheMonitor.shared.getAllCachedItems() {
                await MemoryCacheMonitor.shared.removeItemCategory(key: key)
            }
        }
    }

    /// 키에 해당하는 데이터 존재 여부 확인
    func isCached(forKey key: String) -> Bool {
        cache.object(forKey: key as NSString) != nil
    }

    // 메모리 압박 상황에서 특정 항목 제거
//    func evictItemsIfNeeded() async {
//        // 메모리 사용량이 한계에 가까워지면 제거 실행
//        let memoryUsage = ProcessInfo.processInfo.physicalFootprint
//        let memoryLimit = UInt(ProcessInfo.processInfo.physicalMemory / 4)
//
//        if memoryUsage > memoryLimit * 3 / 4 {
//            // 캐시된 모든 항목 가져오기
//            let items = await MemoryCacheMonitor.shared.getAllCachedItems()
//
//            // 제거 우선순위 계산
//            let evictionOrder = await strategy.priorityForEviction(items: items.map { (key:
//            $0.key, category: $0.category) })
//
//            // 우선순위에 따라 30%의 항목 제거
//            let evictionCount = Int(Double(items.count) * 0.3)
//            for i in 0..<min(evictionCount, evictionOrder.count) {
//                remove(forKey: evictionOrder[i])
//            }
//        }
//    }
}
