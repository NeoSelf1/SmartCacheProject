import Foundation
import UIKit

public final class NeoImageManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let propertyQueue = DispatchQueue(label: "com.neon.NeoImage.NeoImageManagerPropertyQueue")
    
    /// NeoImage 전체에서 사용되는 공유 매니저 인스턴스
    public static let shared = NeoImageManager()
    
    private var _cache: ImageCache
    /// 이 매니저가 사용하는 ImageCache
    public var cache: ImageCache {
        get { propertyQueue.sync { _cache } }
        set { propertyQueue.sync { _cache = newValue } }
    }
    
    private var _downloader: ImageDownloader
    /// 이 매니저가 사용하는 ImageDownloader
    public var downloader: ImageDownloader {
        get { propertyQueue.sync { _downloader } }
        set { propertyQueue.sync { _downloader = newValue } }
    }
    
    /// 매니저에서 사용할 기본 옵션
    public var defaultOptions = NeoImageOptions.default
    
    private let processingQueue: DispatchQueue
    
    // MARK: - Initialization
    
    private convenience init() {
        self.init(downloader: .default, cache: try! ImageCache(name: "default"))
    }
    
    /// 지정된 다운로더와 캐시로 이미지 다운로드 매니저를 생성합니다.
    public init(downloader: ImageDownloader, cache: ImageCache) {
        _downloader = downloader
        _cache = cache
        
        let processQueueName = "com.neon.NeoImage.NeoImageManager.processQueue.\(UUID().uuidString)"
        processingQueue = DispatchQueue(label: processQueueName)
    }
    
    // MARK: - Image Downloading
    
    /// URL에서 이미지를 다운로드하고 처리합니다.
    /// - Parameters:
    ///   - url: 이미지를 다운로드할 URL
    ///   - options: 이미지 처리 옵션
    /// - Returns: 처리된 이미지와 관련 정보를 포함하는 `ImageLoadingResult`
    public func downloadImage(with url: URL, options: NeoImageOptions? = nil) async throws -> ImageLoadingResult {
        let cacheKey = url.absoluteString
        
        if let cachedData = try? await cache.retrieveImage(forKey: cacheKey),
           let cachedImage = UIImage(data: cachedData) {
            return ImageLoadingResult(
                image: cachedImage,
                url: url,
                originalData: cachedData
            )
        }
        
        // 캐시에 없으면 다운로드
        let imageData = try await downloader.downloadImageData(with: url)
        
        guard let image = UIImage(data: imageData) else {
            throw NeoImageError.responseError(reason: .invalidImageData)
        }
        
        // 다운로드 결과 캐싱
        try? await cache.store(imageData, forKey: cacheKey)
        
        let result = ImageLoadingResult(
            image: image,
            url: url,
            originalData: imageData
        )
        
        // 이미지 프로세서가 있으면 이미지 처리
        if let processor = options?.processor {
            let processedImage = try await processor.process(result.image)
            
            return ImageLoadingResult(
                image: processedImage,
                url: url,
                originalData: result.originalData
            )
        }
        
        return result
    }
    
    /// 이미지 다운로드 작업을 취소합니다.
    /// - Parameter url: 취소할 다운로드 작업의 URL
    public func cancelDownload(for url: URL) {
        downloader.cancel(url: url)
    }
    
    /// 모든 다운로드 작업을 취소합니다.
    public func cancelAllDownloads() {
        downloader.cancelAll()
    }
}
