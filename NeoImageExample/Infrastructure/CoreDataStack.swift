import Foundation
import CoreData

/// Core Data 영구 저장소를 관리하는 싱글톤 클래스입니다.
///
/// 앱의 로컬 데이터베이스를 관리하며, 트랜잭션 처리와 데이터 정리 기능을 제공합니다.
/// App Group을 통해 위젯과 데이터베이스를 공유합니다.
///
/// - Important: DataModel.sqlite 파일은 App Group 컨테이너에 저장됩니다.
/// - Warning: Context 작업은 반드시 performInTransaction 메서드를 통해 수행해야 합니다.
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    var persistentContainer: NSPersistentContainer
    
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NeoImageExample")
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 트랜잭션 내에서 작업을 수행하고 자동으로 저장 또는 롤백을 처리하는 메서드
    ///
    /// - Parameter block: 트랜잭션 내에서 실행할 작업
    /// - Throws: 작업 수행 중 발생한 오류
    func performInTransaction(_ block: () throws -> Void) throws {
        // 컨텍스트에서 동기적으로 작업 수행
        try context.performAndWait {
            do {
                // 작업 실행
                try block()
                // 변경사항이 있는 경우에만 저장
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}
