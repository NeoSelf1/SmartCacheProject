import Foundation
import UIKit

public struct ImageLoadingResult: Sendable {
    public let image: UIImage
    public let url: URL?
    public let originalData: Data

    public init(image: UIImage, url: URL? = nil, originalData: Data) {
        self.image = image
        self.url = url
        self.originalData = originalData
    }
}

typealias DownloadResult = Result<ImageLoadingResult, NeoImageError>

public class ImageDownloader: @unchecked Sendable  {
    public static let `default` = ImageDownloader(name: "default")
    private let propertyQueue = DispatchQueue(label: "com.neon.NeoImage.ImageDownloaderPropertyQueue")
    
    private var _downloadTimeout: TimeInterval = 15.0
    open var downloadTimeout: TimeInterval {
        get { propertyQueue.sync { _downloadTimeout } }
        set { propertyQueue.sync { _downloadTimeout = newValue } }
    }
    
    
    private let name: String
    private let session: URLSession
    private let taskManager = TaskManager()
    
    public var requestsUsePipelining = false
    
    open var sessionDelegate: SessionDelegate
    
    public init(name: String) {
        self.name = name
        sessionDelegate = SessionDelegate()
        let configuration = URLSessionConfiguration.ephemeral
        
        session = URLSession(
            configuration: configuration,
            delegate: sessionDelegate,
            delegateQueue: nil)
    }
    
    deinit { session.invalidateAndCancel() }
    
    private func createDownloadContext(with url: URL) async throws -> DownloadingContext {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        request.httpShouldUsePipelining = requestsUsePipelining
        
        guard let url = request.url, !url.absoluteString.isEmpty else {
            throw NeoImageError.requestError(reason: .invalidURL(request: request))
        }
        
        return DownloadingContext(url: url, request: request)
    }
    
    private func createDownloadTask(context: DownloadingContext) async throws -> (DownloadTask, Data) {
        // 여러 요청이 동시에 실행될 경우를 위한 액터 또는 동기화 메커니즘 필요
        return try await withCheckedThrowingContinuation { continuation in
            // 기존 태스크 확인 (중복 다운로드 방지)
            if let existingTask = sessionDelegate.task(for: context.url) {
                let downloadTask = DownloadTask()
                // 새로운 콜백을 정의하여 결과를 반환
                let delegate = Delegate<DownloadResult, Void>()
                delegate.delegate(on: self) { (self, result) in
                    switch result {
                    case .success(let imageResult):
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                let callback = SessionDataTask.TaskCallback(onCompleted: delegate)
                
                // 기존 태스크에 새 콜백 추가
                let task = sessionDelegate.append(existingTask, callback: callback)
                downloadTask.linkToTask(task)
                print("5")
            } else {
                // 새로운 다운로드 태스크 생성
                let sessionDataTask = session.dataTask(with: context.request)
                
                // 완료 콜백 정의
                let delegate = Delegate<DownloadResult, Void>()
                delegate.delegate(on: self) { (self, result) in
                    switch result {
                    case .success(let imageResult):
                        let downloadTask = DownloadTask()
                        downloadTask.linkToTask(downloadTask)
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                let callback = SessionDataTask.TaskCallback(onCompleted: delegate)
                
                // 세션 델리게이트에 태스크 추가
                let downloadTask = sessionDelegate.add(sessionDataTask, url: context.url, callback: callback)
                
                // 다운로드 시작
                sessionDataTask.resume()
            }
        }
    }
    
    @discardableResult
    open func downloadImageData(with url: URL) async throws -> Data {
        let downloadTask = DownloadTask()
    
        let context = try await createDownloadContext(with: url)
        
        let (actualDownloadTask, imageData) = try await createDownloadTask(context: context) // MARK: error

        downloadTask.linkToTask(actualDownloadTask)
        
        return imageData
    }
    
    /// Downloads an image with a URL and option.
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options that can control download behavior.
    /// - Returns: The image loading result.
    public func downloadImage(with url: URL) async throws -> ImageLoadingResult {
        // 이미지 데이터 다운로드
        let imageData = try await downloadImageData(with: url)
        
        guard let image = UIImage(data: imageData) else {
            throw NeoImageError.responseError(reason: .invalidImageData)
        }
        
        return ImageLoadingResult(image: image, url: url, originalData: imageData)
    }
    
    /// Cancel all downloading tasks for a given URL.
    public func cancel(url: URL) {
        taskManager.cancel(url: url)
    }
    
    /// Cancel all downloading tasks.
    public func cancelAll() {
        taskManager.cancelAll()
    }
}

extension ImageDownloader {
    struct DownloadingContext {
        let url: URL
        let request: URLRequest
    }
}
