import Foundation

public actor DiskStorage<T: DataTransformable> {
    private let name: String
    private let fileManager: FileManager
    private let directoryURL: URL
    private var storageReady = true
    
    var maybeCached : Set<String>?
    
    let metaChangingQueue: DispatchQueue
    
    // MARK: - Lifecycle
    
    init (
        name: String,
        fileManager: FileManager
    ) {
        self.name = name
        self.fileManager = fileManager
        
        let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cacheName = "com.neon.NeoImage.ImageCache.\(name)"
        
        directoryURL = url.appendingPathComponent(cacheName, isDirectory: true)
        
        metaChangingQueue = DispatchQueue(label: cacheName)
        
        Task {
            await setupCacheChecking()
            try? await prepareDirectory()
        }
    }
    
    // MARK: - Functions
    
    func store(value: T, forKey key: String, expiration: StorageExpiration? = nil) async throws {
        guard storageReady else {
            throw CacheError.storageNotReady
        }
        
        let expiration = expiration ?? NeoImageConstants.expiration
        
        guard !expiration.isExpired else { return }
        
        guard let data = try? value.toData() else {
            throw CacheError.cannotConvertToData(object: value)
        }
        
        let fileURL = cacheFileURL(forKey: key)
        
        // Foundation 내부 Data 타입의 내장 메서드입니다.
        // 해당 위치로 data 내부 컨텐츠를 write 합니다.
        try data.write(to: fileURL)
        
        
        // FileManager를 통해 파일 작성 시 전달해줄 파일의 속성입니다.
        // 생성된 날짜, 수정된 일자를 실제 수정된 시간이 아닌, 만료 예정 시간을 저장하는 용도로 재활용합니다.
        // 실제로, 파일 시스템의 기본속성을 활용하기에 추가적인 저장공간이 필요 없음
        // 파일과 만료 정보가 항상 동기화되어 있음 (파일이 삭제되면 만료 정보도 자동으로 삭제)
        let attributes: [FileAttributeKey: Sendable] = [
            .creationDate: Date(),
            .modificationDate: expiration.estimatedExpirationSinceNow,
        ]
        
        // 파일의 메타데이터가 업데이트됨
        // 이는 디스크에 대한 I/O 작업을 수반
        do {
            try fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)
        } catch {
            try? fileManager.removeItem(at: fileURL)
            
            throw CacheError.cannotSetCacheFileAttribute(
                filePath: fileURL.path,
                attributes: attributes,
                error: error
            )
        }
        
        self.maybeCached?.insert(fileURL.lastPathComponent)
    }
    
    
    func value(
        forKey key: String, // 캐시의 키
        actuallyLoad: Bool = true,
        extendingExpiration: ExpirationExtending = .cacheTime // 현재 Config
    ) async throws -> T? {
        guard storageReady else {
            throw CacheError.storageNotReady
        }
        
        let fileURL = cacheFileURL(forKey: key)
        let filePath = fileURL.path
        guard maybeCached?.contains(fileURL.lastPathComponent) ?? true else {
            return nil
        }
        
        guard fileManager.fileExists(atPath: filePath) else {
            return nil
        }
        
        if !actuallyLoad { return T.empty }
        
        // 파일에서 데이터를 읽어옴
        let data = try Data(contentsOf: fileURL)
        
        // DataTransformable 프로토콜의 fromData를 사용해 원본 타입으로 변환
        let obj = try T.fromData(data)
        
        // 해당 파일이 조회되었기 때문에, 만료 시간 연장을 처리합니다.
        // "캐시 적중(Cache Hit)"이 발생했을 때 해당 데이터의 생명주기를 연장하는 일반적인 캐시 전략입니다.
        // LRU(Least Recently Used)
        if extendingExpiration != .none {
            let expirationDate: Date
            switch extendingExpiration {
            case .none:
                return obj
            case .cacheTime:
                expirationDate = NeoImageConstants.expiration.estimatedExpirationSinceNow
                // .expirationTime: 지정된 새로운 만료 시간으로 연장
            case let .expirationTime(storageExpiration):
                expirationDate = storageExpiration.estimatedExpirationSinceNow
            }
            
            metaChangingQueue.async {
                let attributes: [FileAttributeKey: Any] = [
                    .creationDate: Date(),
                    .modificationDate: expirationDate,
                ]
                
                try? FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
            }
        }
        
        return obj
    }
    
    /// 특정 키에 해당하는 파일을 삭제하는 메서드
    func remove(forKey key: String) async throws {
        let fileURL = cacheFileURL(forKey: key)
        try fileManager.removeItem(at: fileURL)
    }


    /// 디렉토리 내의 모든 파일을 삭제하는 메서드
    func removeAll() async throws {
        try fileManager.removeItem(at: directoryURL)
        try prepareDirectory()
    }
    
    func isCached(forKey key: String) async -> Bool {
        do {
            let result = try await value(
                forKey: key,
                actuallyLoad: false
            )
            
            return result != nil
        } catch {
            return false
        }
    }
    
    func removeExpiredValues() throws -> [URL] {
        return try removeExpiredValues(referenceDate: Date())
    }
}

extension DiskStorage {
    private func cacheFileURL(forKey key: String) -> URL {
        let fileName = cacheFileName(forKey: key)
        return directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
    
    /// 사전에 패키지에서 설정된 Config 구조체를 통해 파일명을 해시화하기로 설정했는지 여부, 임의로 전달된 접미사 단어 유무에 따라 캐시될때 저장될 파일명을 변환하여
    /// 반환해줍니다.
    private func cacheFileName(forKey key: String) -> String {
        return key.sha256
    }
    
    // MARK: - 만료기간 종료 여부 파악 관련 메서드들
    func removeExpiredValues(referenceDate: Date) throws -> [URL] {
        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .contentModificationDateKey
        ]

        let urls = try allFileURLs(for: propertyKeys)
        let keys = Set(propertyKeys)
        let expiredFiles = urls.filter { fileURL in
            do {
                let meta = try FileMeta(fileURL: fileURL, resourceKeys: keys)
                return meta.expired(referenceDate: referenceDate)
            } catch {
                return true
            }
        }
        
        try expiredFiles.forEach { url in
            try fileManager.removeItem(at: url)
        }
        return expiredFiles
    }
    
    private func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {

        guard let directoryEnumerator = fileManager.enumerator(
            at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else
        {
            throw CacheError.fileEnumeratorCreationFailed
        }

        guard let urls = directoryEnumerator.allObjects as? [URL] else {
            throw CacheError.fileEnumeratorCreationFailed
        }
        return urls
    }
    
    private func setupCacheChecking() {
        do {
            self.maybeCached = Set()
            try self.fileManager.contentsOfDirectory(atPath: self.directoryURL.path).forEach {
                fileName in
                self.maybeCached?.insert(fileName)
            }
        } catch {
            self.maybeCached = nil
        }
    }
    
    private func prepareDirectory() throws {
        // config에 custom fileManager를 주입할 수 있기 때문에, 여기서 .default를 접근하지 않고 Config 내부 fileManager를
        // 접근합니다.
        let path = directoryURL.path
        
        // Creation 구조체를 통해 생성된 url이 FileSystem에 존재하는지 검증
        guard !fileManager.fileExists(atPath: path) else {
            return
        }
        
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            // 만일 디렉토리 생성이 실패할경우, storageReady를 false로 변경합니다.
            // 이는 추후 flag로 동작합니다.
            print("error creating New Directory")
            storageReady = false
            throw CacheError.cannotCreateDirectory(error)
        }
    }
}


extension DiskStorage {
    struct FileMeta {
        let url: URL
        let lastAccessDate: Date?
        let estimatedExpirationDate: Date?
        
        init(fileURL: URL, resourceKeys: Set<URLResourceKey>) throws {
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            self.init(
                fileURL: fileURL,
                lastAccessDate: meta.creationDate,
                estimatedExpirationDate: meta.contentModificationDate
            )
        }
        
        init(
            fileURL: URL,
            lastAccessDate: Date?,
            estimatedExpirationDate: Date?
        ){
            self.url = fileURL
            self.lastAccessDate = lastAccessDate
            self.estimatedExpirationDate = estimatedExpirationDate
        }

        func expired(referenceDate: Date) -> Bool {
            return estimatedExpirationDate?.isPast(referenceDate: referenceDate) ?? true
        }
        
        func extendExpiration(with fileManager: FileManager, extendingExpiration: ExpirationExtending) {
            guard let lastAccessDate = lastAccessDate,
                  let lastEstimatedExpiration = estimatedExpirationDate else
            {
                return
            }

            let attributes: [FileAttributeKey : Any]

            switch extendingExpiration {
            case .none:
                // not extending expiration time here
                return
            case .cacheTime:
                let originalExpiration: StorageExpiration =
                    .seconds(lastEstimatedExpiration.timeIntervalSince(lastAccessDate))
                attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: originalExpiration.estimatedExpirationSinceNow.fileAttributeDate
                ]
            case .expirationTime(let expirationTime):
                attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: expirationTime.estimatedExpirationSinceNow.fileAttributeDate
                ]
            }

            try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
}
