import Foundation
import UIKit

/// 쓰기 제어와 같은 동시성이 필요한 부분만 선택적으로 제어하기 위해 전체 ImageCache를 actor로 변경하지 않고, ImageCacheActor 생성
/// actor를 사용하면 모든 동작이 actor의 실행큐를 통과해야하기 때문에, 동시성 보호가 불필요한 read-only 동작도 직렬화되며 오버헤드가 발생
public final class ImageCache: Sendable {
    // MARK: - Static Properties
    
    /// ERROR: Static property 'shared' is not concurrency-safe because non-'Sendable' type
    /// 'ImageCache' may have shared mutable state
    /// ```
    /// public static let shared = ImageCache()
    /// ```
    /// Swift 6에서는 동시성 안정성 검사가 더욱 엄격해졌습니다. 이로 인해 여러 스레드에서 동시에 접근할 수 있는 공유 상태 (shared mutable state)인
    /// 싱글톤 패턴을 사용할 경우,위 에러가 발생합니다.
    /// 이는 별도의 가변 프로퍼티를 클래스 내부에 지니고 있지 않음에도 발생하는 에러입니다
    /// 이를 해결하기 위해선, Actor를 사용하거나, Serial Queue를 사용해 동기화를 해줘야 합니다.
    ///
    public static let shared = ImageCache(name: "default")
    
    // MARK: - Properties
    
    public let memoryStorage: MemoryStorage
    public let diskStorage: DiskStorage<Data>
    
    // Disk에 대한 접근이 패키지 외부에서 동시에 이루어질 경우, 동일한 위치에 다른 데이터가 덮어씌워지는 data race 상황이 됩니다. 이를 방지하고자, 기존
    // Kingfisher에서는 DispatchQueue를 통해  직렬화 큐를 구현한 후, store(Write), value(Read)를 직렬화 큐에 전송하여
    // 순차적인 실행이 보장되게 하였습니다.
    
    // MARK: - Lifecycle
    
    // MARK: - Initialization
    public init(
        name: String
    ) {
        if name.isEmpty {
            fatalError("You should specify a name for the cache. A cache with empty name is not permitted.")
        }
        
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryLimit = totalMemory / 4
        
        memoryStorage = MemoryStorage(
            totalCostLimit: min(Int.max, Int(memoryLimit))
        )
        
        diskStorage = DiskStorage<Data>(
            name: name,
            fileManager: .default
        )
        
        Task { @MainActor in
            let notifications: [(Notification.Name, Selector)]
            notifications = [
                (UIApplication.didReceiveMemoryWarningNotification, #selector(clearMemoryCache)),
                (UIApplication.willTerminateNotification, #selector(cleanExpiredDiskCache))
            ]
            
            notifications.forEach {
                NotificationCenter.default.addObserver(self, selector: $0.1, name: $0.0, object: nil)
            } // 각 알림에 대해 옵저버 등록
        }
    }
    
    // MARK: - Functions
    
    /// 메모리와 디스크 캐시에 모두 데이터를 저장합니다.
    public func store(
        _ data: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) async throws {
        memoryStorage.store(value: data, forKey: key, expiration: expiration)
        
        try await diskStorage.store(
            value: data,
            forKey: key,
            expiration: expiration
        )
    }
    
    public func retrieveImage(forKey key: String) async throws -> Data? {
        if let memoryData = memoryStorage.value(forKey: key) {
            return memoryData
        }
        
        let diskData = try await diskStorage.value(forKey: key)
        
        if let diskData {
            memoryStorage.store(
                value: diskData,
                forKey: key,
                expiration: .days(7)
            )
        }
        
        return diskData
    }
    
    /// 메모리와 디스크 모두에 존재하는 모든 데이터를 제거합니다.
    public func clearCache() async throws {
        memoryStorage.removeAll()
        
        try await diskStorage.removeAll()
    }
    
    @objc public func clearMemoryCache() {
        memoryStorage.removeAll()
    }
    
    @objc func cleanExpiredDiskCache() {
        Task {
            do {
                var removed: [URL] = []
                let removedExpired = try await self.diskStorage.removeExpiredValues()
                removed.append(contentsOf: removedExpired)
            } catch {}
        }
    }
}
