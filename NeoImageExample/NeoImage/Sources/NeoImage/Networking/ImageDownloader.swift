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
            delegateQueue: nil
        )
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
                existingTask.onTaskDone.delegate(on: self) { (_, values) in
                    let (result, callbacks) = values
                    let downloadResult: DownloadResult
                    
                    switch result {
                    case .success(let (data, _)):
                        if let image = UIImage(data: data) {
                            let imageResult = ImageLoadingResult(
                                image: image,
                                url: context.url,
                                originalData: data
                            )
                            
                            downloadResult = .success(imageResult)
                        } else {
                            downloadResult = .failure(NeoImageError.responseError(reason: .invalidImageData))
                        }
                    case .failure(let error):
                        downloadResult = .failure(error)
                    }
                    
                    // 모든 콜백 호출
                    for callbackItem in callbacks {
                        callbackItem.onCompleted?.call(downloadResult)
                    }
                }
                
                let downloadTask = DownloadTask()
                
                // 객체를 생성, TaskCallback으로 래핑하여 add 메서드에 전달
                let onCompleted = Delegate<DownloadResult, Void>()
                
                onCompleted.delegate(on: self) { (self, result) in
                    switch result {
                    case .success(let imageResult):
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                let callback = SessionDataTask.TaskCallback(onCompleted: onCompleted)
                let task = sessionDelegate.append(existingTask, callback: callback)
                
                downloadTask.linkToTask(task)
            } else {
                let sessionDataTask = session.dataTask(with: context.request)
                let onCompleted = Delegate<DownloadResult, Void>()
                let callback = SessionDataTask.TaskCallback(onCompleted: onCompleted)
                let downloadTask = sessionDelegate.add(sessionDataTask, url: context.url, callback: callback)
                
                downloadTask.sessionTask?.onTaskDone.delegate(on: self) { (_, values) in
                    let (result, callbacks) = values
                    
                    // 결과를 DownloadResult로 변환
                    let downloadResult: DownloadResult
                    switch result {
                    case .success(let (data, _)):
                        if let image = UIImage(data: data) {
                            let imageResult = ImageLoadingResult(
                                image: image,
                                url: context.url,
                                originalData: data
                            )
                            downloadResult = .success(imageResult)
                        } else {
                            downloadResult = .failure(NeoImageError.responseError(reason: .invalidImageData))
                        }
                    case .failure(let error):
                        downloadResult = .failure(error)
                    }
                    
                    // 모든 콜백 호출
                    for callbackItem in callbacks {
                        callbackItem.onCompleted?.call(downloadResult)
                    }
                }
                
                onCompleted.delegate(on: self) { (self, result) in
                    switch result {
                    case .success(let imageResult):
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                // 다운로드 시작
                sessionDataTask.resume()
            }
        }
    }
    
    @discardableResult
    open func downloadImageData(with url: URL) async throws -> Data {
        let downloadTask = DownloadTask()
    
        let context = try await createDownloadContext(with: url)
        let (actualDownloadTask, imageData) = try await createDownloadTask(context: context)
        
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
