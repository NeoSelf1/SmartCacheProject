import Foundation

enum CacheError: @unchecked Sendable, Error {
    // 데이터 관련 에러
    case invalidData
    case invalidImage
    case dataToImageConversionFailed
    case imageToDataConversionFailed

    case fileEnumeratorCreationFailed
    
    // 저장소 관련 에러
    case diskStorageError(Error)
    case memoryStorageError(Error)
    case storageNotReady

    // 파일 관련 에러
    case fileNotFound(String) // key
    case cannotCreateDirectory(Error)
    case cannotWriteToFile(Error)
    case cannotReadFromFile(Error)

    case invalidURLResource
    case cannotConvertToData(object: Any)
    case cannotSetCacheFileAttribute(filePath: String, attributes: [FileAttributeKey : Any], error: any Error)
    
    /// 캐시 키 관련 에러
    case invalidCacheKey

    /// 기타
    case unknown(Error)

    // MARK: - Computed Properties

    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "The data is invalid or corrupted"
        case .invalidImage:
            return "The image data is invalid"
        case .dataToImageConversionFailed:
            return "Failed to convert data to image"
        case .imageToDataConversionFailed:
            return "Failed to convert image to data"
        case let .diskStorageError(error):
            return "Disk storage error: \(error.localizedDescription)"
        case let .memoryStorageError(error):
            return "Memory storage error: \(error.localizedDescription)"
        case .storageNotReady:
            return "The storage is not ready"
        case let .fileNotFound(key):
            return "File not found for key: \(key)"
        case let .cannotCreateDirectory(error):
            return "Cannot create directory: \(error.localizedDescription)"
        case let .cannotWriteToFile(error):
            return "Cannot write to file: \(error.localizedDescription)"
        case let .cannotReadFromFile(error):
            return "Cannot read from file: \(error.localizedDescription)"
        case .invalidCacheKey:
            return "The cache key is invalid"
        case let .unknown(error):
            return "Unknown error: \(error.localizedDescription)"
        default:
            return ""
        }
    }
}

public enum NeoImageError: Error {
    case requestError(reason: RequestErrorReason)
    case responseError(reason: ResponseErrorReason)
    
    public enum RequestErrorReason: Sendable {
        case invalidURL(request: URLRequest)
        case emptyRequest
        case taskCancelled(task: SessionDataTask, token: Int)
    }
    
    public enum ResponseErrorReason: Sendable {
        case URLSessionError(description: String)
        case cancelled
        case invalidImageData
    }
}
