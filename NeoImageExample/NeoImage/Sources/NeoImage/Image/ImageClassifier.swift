import CoreML
import UIKit
import Vision

public actor ImageClassifier: Sendable {
    // MARK: - Static Properties

    public static let shared = ImageClassifier()

    // MARK: - Properties

    private var model: VNCoreMLModel?
    private var isModelLoaded = false

    // MARK: - Lifecycle

    private init() {
        do {
            let config = MLModelConfiguration()
            let objectDetector = try MobileNetV2(configuration: config)
            model = try VNCoreMLModel(for: objectDetector.model)

            isModelLoaded = true
        } catch {
            print("CoreML 모델 로드 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Functions

    /// 이미지를 분류하여 카테고리를 반환하는 메서드
    public func classifyImage(_ image: UIImage) async throws -> ImageCategory {
        guard isModelLoaded, let model else {
            throw CacheError.invalidData
        }

        guard let ciImage = CIImage(image: image) else {
            throw CacheError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: .unknown)
                    return
                }

                let category = ImageCategory.fromClassificationIdentifier(topResult.identifier)
                continuation.resume(returning: category)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(ciImage: ciImage)

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
