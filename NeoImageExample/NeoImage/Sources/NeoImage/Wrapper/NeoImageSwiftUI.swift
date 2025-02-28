import SwiftUI
import UIKit

/// SwiftUI에서 사용 가능한 비동기 이미지 로딩 View
public struct NeoImage: View {
    private let source: Source
    private var placeholder: AnyView?
    private var options: NeoImageOptions
    private var onSuccess: ((ImageLoadingResult) -> Void)?
    private var onFailure: ((Error) -> Void)?
    private var contentMode: SwiftUI.ContentMode
    private var frame: CGSize? // 명시적인 프레임 크기 추가
    
    /// 이미지 소스를 나타내는 열거형
    public enum Source {
        case url(URL?)
        case urlString(String?)
    }
    
    // MARK: - Initializers
    
    /// URL로 초기화
    public init(url: URL?) {
        self.source = .url(url)
        self.options = .default
        self.contentMode = .fill
        self.frame = nil
    }
    
    /// URL 문자열로 초기화
    public init(urlString: String?) {
        self.source = .urlString(urlString)
        self.options = .default
        self.contentMode = .fill
        self.frame = nil
    }
    
    // MARK: - View 구현
    
    public var body: some View {
        NeoImageViewRepresenter(
            source: source,
            placeholder: placeholder,
            options: options,
            contentMode: contentMode,
            frame: frame,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
        .if(frame != nil) { view in
            view.frame(width: frame?.width, height: frame?.height)
        }
        .clipped() // 이미지가 경계를 넘지 않도록 클리핑
    }
    
    // MARK: - 모디파이어
    
    /// 플레이스홀더 이미지 설정
    public func placeholder(_ content: @escaping () -> some View) -> NeoImage {
        var result = self
        result.placeholder = AnyView(content())
        return result
    }
    
    /// 옵션 설정
    public func options(_ options: NeoImageOptions) -> NeoImage {
        var result = self
        result.options = options
        return result
    }
    
    /// 이미지 로딩 성공 시 호출될 콜백
    public func onSuccess(_ action: @escaping (ImageLoadingResult) -> Void) -> NeoImage {
        var result = self
        result.onSuccess = action
        return result
    }
    
    /// 이미지 로딩 실패 시 호출될 콜백
    public func onFailure(_ action: @escaping (Error) -> Void) -> NeoImage {
        var result = self
        result.onFailure = action
        return result
    }
    
    /// 이미지 프로세서 설정 모디파이어
    public func processor(_ processor: ImageProcessing) -> NeoImage {
        var result = self
        result.options = NeoImageOptions(
            processor: processor,
            transition: result.options.transition,
            retryStrategy: result.options.retryStrategy,
            cacheExpiration: result.options.cacheExpiration
        )
        return result
    }
    
    /// 페이드 트랜지션 설정
    public func fade(duration: TimeInterval = 0.3) -> NeoImage {
        var result = self
        result.options = NeoImageOptions(
            processor: result.options.processor,
            transition: .fade(duration),
            retryStrategy: result.options.retryStrategy,
            cacheExpiration: result.options.cacheExpiration
        )
        return result
    }
}

// MARK: - UIViewRepresentable 구현

struct NeoImageViewRepresenter: UIViewRepresentable {
    let source: NeoImage.Source
    let placeholder: AnyView?
    let options: NeoImageOptions
    let contentMode: SwiftUI.ContentMode
    let frame: CGSize?
    let onSuccess: ((ImageLoadingResult) -> Void)?
    let onFailure: ((Error) -> Void)?
    
    @State private var imageTask: ImageTask?
    
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        
        // ContentMode 매핑
        switch contentMode {
        case .fill:
            imageView.contentMode = .scaleAspectFill
        case .fit:
            imageView.contentMode = .scaleAspectFit
        }
        
        // Allow SwiftUI scale (fit/fill) working fine.
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // URL 추출
        let url: URL? = {
            switch source {
            case .url(let url):
                return url
            case .urlString(let string):
                if let string = string {
                    return URL(string: string)
                }
                return nil
            }
        }()
        
        Task {
            do {
                let result = try await uiView.neo.setImage(with: url, options: options)
                
                if let onSuccess = onSuccess {
                    await MainActor.run {
                        onSuccess(result)
                    }
                }
            } catch {
                if let onFailure = onFailure {
                    await MainActor.run {
                        onFailure(error)
                    }
                }
            }
        }
    }
}

// MARK: - View Extensions for NeoImage

/// NeoImage 생성을 위한 편의 확장
public extension View {
    /// URL로부터 NeoImage를 생성하는 모디파이어
    func neoImage(url: URL?, placeholder: AnyView? = nil, options: NeoImageOptions = .default) -> some View {
        let neoImage = NeoImage(url: url)
            .options(options)
        
        if let placeholder = placeholder {
            return neoImage.placeholder { placeholder }
        }
        
        return neoImage
    }
    
    /// URL 문자열로부터 NeoImage를 생성하는 모디파이어
    func neoImage(urlString: String?, placeholder: AnyView? = nil, options: NeoImageOptions = .default) -> some View {
        let neoImage = NeoImage(urlString: urlString)
            .options(options)
        
        if let placeholder = placeholder {
            return neoImage.placeholder { placeholder }
        }
        
        return neoImage
    }
}
