import Foundation
import UIKit

/// 다운로드 작업을 관리하는 클래스입니다.
/// 이 클래스는 URL 기반으로 작업을 추적하며, 동일한 URL에 대한 중복 다운로드를 방지합니다.
public class TaskManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 스레드 안전성을 위한 동시성 큐
    private let taskQueue = DispatchQueue(label: "com.neon.NeoImage.TaskManagerQueue", attributes: .concurrent)
    
    /// URL을 키로 하여 다운로드 작업과 콜백을 저장하는 딕셔너리
    private var tasks: [URL: SessionDataTask] = [:]
    
    // MARK: - Public Methods
    
    /// 특정 URL에 대한 다운로드 작업을 가져옵니다.
    /// - Parameter url: 확인할 URL
    /// - Returns: 해당 URL에 대한 SessionDataTask (존재하는 경우)
    public func task(for url: URL) -> SessionDataTask? {
        return taskQueue.sync { tasks[url] }
    }
    
    /// 다운로드 작업을 추가합니다.
    /// - Parameters:
    ///   - task: URLSessionDataTask
    ///   - url: 다운로드 URL
    ///   - callback: 완료 시 호출될 콜백
    /// - Returns: 생성된 DownloadTask
    public func add(_ task: SessionDataTask, url: URL) -> DownloadTask {
        let downloadTask = DownloadTask()
        
        taskQueue.async(flags: .barrier) {
            self.tasks[url] = task
        }
        
        return downloadTask
    }
    
    /// 특정 URL에 대한 다운로드 작업을 제거합니다.
    /// - Parameter url: 제거할 작업의 URL
    public func remove(for url: URL) {
        taskQueue.async(flags: .barrier) {
            self.tasks.removeValue(forKey: url)
        }
    }
    
    /// 특정 URL에 대한 다운로드를 취소합니다.
    /// - Parameter url: 취소할 다운로드의 URL
    public func cancel(url: URL) {
        taskQueue.async(flags: .barrier) {
            guard let task = self.tasks[url] else { return }
            
            task.forceCancel()
            self.tasks.removeValue(forKey: url)
        }
    }
    
    /// 모든 다운로드 작업을 취소합니다.
    public func cancelAll() {
        taskQueue.async(flags: .barrier) {
            for (_, task) in self.tasks {
                task.forceCancel()
            }
            
            self.tasks.removeAll()
        }
    }
    
    /// 특정 URL에 대한 이미지 다운로드가 완료되었을 때 호출합니다.
    /// - Parameters:
    ///   - url: 완료된 다운로드의 URL
    ///   - result: 다운로드 결과
    func complete(for url: URL, with result: ImageLoadingResult) {
        let task = taskQueue.sync {
            let task = self.tasks[url]
            self.tasks.removeValue(forKey: url)
            return task
        }
        
        // 여기서는 SessionDataTask가 자체적으로 콜백 처리를 하므로,
        // 추가적인 콜백 호출은 필요 없습니다.
    }
}
