import Foundation

/// 이미지 작업을 나타내는 클래스로, 취소 기능을 제공합니다.
public class ImageTask: @unchecked Sendable {
    private let propertyQueue = DispatchQueue(label: "com.neon.NeoImage.ImageTaskPropertyQueue")
    
    private var _downloadTask: DownloadTask?
    public private(set) var downloadTask: DownloadTask? {
        get { propertyQueue.sync { _downloadTask } }
        set { propertyQueue.sync { _downloadTask = newValue } }
    }
    
    private var _isCancelled = false
    public private(set) var isCancelled: Bool {
        get { propertyQueue.sync { _isCancelled } }
        set { propertyQueue.sync { _isCancelled = newValue } }
    }
    
    public init() {}
    
    /// 작업을 취소합니다.
    public func cancel() async {
        await MainActor.run {
            isCancelled = true
            downloadTask?.cancel()
        }
    }
    
    /// 작업이 실패했음을 표시합니다.
    public func fail() async {
        await MainActor.run {
            isCancelled = true
        }
    }
    
    /// 다운로드 작업을 설정합니다.
    public func setDownloadTask(_ task: DownloadTask) {
        downloadTask = task
    }
}
