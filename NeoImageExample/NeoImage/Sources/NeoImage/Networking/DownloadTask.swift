import Foundation

public final class DownloadTask: @unchecked Sendable {
    // DownloadTask의 속성 접근을 동기화하기 위한 직렬 DispatchQueue를 생성
    // 여러 스레드에서 속성에 안전하게 접근할 수 있도록 보장
    private let propertyQueue = DispatchQueue(label: "com.neon.NeoImage.DownloadTaskPropertyQueue")
    
    init(sessionTask: SessionDataTask, cancelToken: SessionDataTask.CancelToken) {
        _sessionTask = sessionTask
        _cancelToken = cancelToken
    }
    
    init() { }

    private var _sessionTask: SessionDataTask? = nil
    /// 복수개의 DownloadTask는 동일한 sessionTask를 참조할 수 있습니다.
    /// 이를 매개체 삼아 두개 이상의 DownloadTask가 동일한 url을 지녔을 경우 중복된 다운로드를 방지하게 됩니다.
    public private(set) var sessionTask: SessionDataTask? {
        get { propertyQueue.sync { _sessionTask } }
        set { propertyQueue.sync { _sessionTask = newValue } }
    }

    private var _cancelToken: SessionDataTask.CancelToken? = nil
    
    /// Task를 취소하기 위해 사용되는 토큰입니다.
    /// DownloadTask를 cancel하기에 앞서, DownloadTask.cancleToken을 호출해 토큰을 접근해야합니다.
    public private(set) var cancelToken: SessionDataTask.CancelToken? {
        get { propertyQueue.sync { _cancelToken } }
        set { propertyQueue.sync { _cancelToken = newValue } }
    }

    /// Cancel this single download task if it is running.
    public func cancel() {
        guard let sessionTask, let cancelToken else { return }
        sessionTask.cancel(token: cancelToken)
    }
    
    // DownloadTask가 제대로 초기화되었는지 확인하는 메서드
    public var isInitialized: Bool {
        propertyQueue.sync {
            _sessionTask != nil && _cancelToken != nil
        }
    }
    
    // 다른 DownloadTask의 sessionTask와 cancelToken을 이 DownloadTask에 연결
    func linkToTask(_ task: DownloadTask) {
        self.sessionTask = task.sessionTask
        self.cancelToken = task.cancelToken
    }
}
