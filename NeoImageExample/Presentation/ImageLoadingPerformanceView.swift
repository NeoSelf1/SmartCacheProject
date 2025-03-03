import SwiftUI
import NeoImage
import Kingfisher

struct ImageLoadingPerformanceView: View {
    @StateObject private var viewModel = PerformanceViewModel()
    @State private var isViewPresent = true
    
    var body: some View {
        VStack {
            HStack {
                Button("Clear Cache") {
                    viewModel.clearCache()
                }
                .buttonStyle(.bordered)
                
                Button("뷰 렌더여부 토글") {
                    if isViewPresent {
                        viewModel.initialize()
                    }
                    isViewPresent.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                if isViewPresent {
                    VStack {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(0..<9) { row in
                                    HStack(spacing: 10) {
                                        NeoImageTestView(viewModel: viewModel, size: 160, id: row * 4)
                                        NeoImageTestView(viewModel: viewModel, size: 160, id: row * 4 + 1)
                                        
                                        KingfisherTestView(viewModel: viewModel, size: 160, id: row * 4)
                                        KingfisherTestView(viewModel: viewModel, size: 160, id: row * 4 + 1)
                                    }
                                    
                                    HStack(spacing: 10) {
                                        NeoImageTestView(viewModel: viewModel, size: 160, id: row * 4 + 2)
                                        NeoImageTestView(viewModel: viewModel, size: 160, id: row * 4 + 3)
                                        
                                        KingfisherTestView(viewModel: viewModel, size: 160, id: row * 4 + 2)
                                        KingfisherTestView(viewModel: viewModel, size: 160, id: row * 4 + 3)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ImageLoadingPerformanceView()
}

struct NeoImageTestView: View {
    @ObservedObject var viewModel: PerformanceViewModel
    
    let size: CGFloat
    let id: Int
    
    init(viewModel: PerformanceViewModel, size: CGFloat, id: Int) {
        self.viewModel = viewModel
        self.size = size
        self.id = id
    }
    
    @State private var startTime: Date = Date()
    
    var body: some View {
        NeoImage(url: viewModel.testImageURLs[id])
            .onSuccess { _ in
                viewModel.neoImageData[id] = Date().timeIntervalSince(startTime)
            }
            .frame(maxWidth: size, maxHeight: size)
    }
}

struct KingfisherTestView: View {
    @ObservedObject var viewModel: PerformanceViewModel
    
    let size: CGFloat
    let id: Int
    
    init(viewModel: PerformanceViewModel, size: CGFloat, id: Int) {
        self.viewModel = viewModel
        self.size = size
        self.id = id
    }
    
    private var startTime: Date = Date()
    
    var body: some View {
        KFImage(viewModel.testImageURLs[id])
            .onSuccess { _ in
                viewModel.kingfisherData[id] = Date().timeIntervalSince(startTime)
            }
            .resizable()
            .frame(maxWidth: size, maxHeight: size)
    }
}

// 성능 테스트 뷰모델
class PerformanceViewModel: ObservableObject {
    
    @Published var neoImageData: [Double] = Array(repeating: 0, count: 12) {
        didSet {
            checkNeoImageCompletion()
        }
    }
    
    @Published var kingfisherData: [Double] = Array(repeating: 0, count: 12) {
        didSet {
            checkKingfisherCompletion()
        }
    }
    
    let gridImageCount = 12
    
    // 성능 통계 프로퍼티
    @Published var neoImageAverageTime: Double = 0
    @Published var neoImageMinTime: Double = 0
    @Published var neoImageMaxTime: Double = 0
    
    @Published var kingfisherAverageTime: Double = 0
    @Published var kingfisherMinTime: Double = 0
    @Published var kingfisherMaxTime: Double = 0
    
    // 로드 완료 상태
    @Published var neoImageLoadCompleted: Bool = false
    @Published var kingfisherLoadCompleted: Bool = false
    
    // 테스트용 이미지 URL 목록
    let testImageURLs: [URL] = [
        URL(string: "https://picsum.photos/id/1/1200/1200")!,
        URL(string: "https://picsum.photos/id/2/1200/1200")!,
        URL(string: "https://picsum.photos/id/3/1200/1200")!,
        URL(string: "https://picsum.photos/id/4/1200/1200")!,
        URL(string: "https://picsum.photos/id/5/1200/1200")!,
        URL(string: "https://picsum.photos/id/6/1200/1200")!,
        URL(string: "https://picsum.photos/id/7/1200/1200")!,
        URL(string: "https://picsum.photos/id/8/1200/1200")!,
        URL(string: "https://picsum.photos/id/9/1200/1200")!,
        URL(string: "https://picsum.photos/id/10/1200/1200")!,
        URL(string: "https://picsum.photos/id/11/1200/1200")!,
        URL(string: "https://picsum.photos/id/12/1200/1200")!,
        URL(string: "https://picsum.photos/id/13/1200/1200")!,
        URL(string: "https://picsum.photos/id/14/1200/1200")!,
        URL(string: "https://picsum.photos/id/15/1200/1200")!,
        URL(string: "https://picsum.photos/id/16/1200/1200")!,
        URL(string: "https://picsum.photos/id/17/1200/1200")!,
        URL(string: "https://picsum.photos/id/18/1200/1200")!,
        URL(string: "https://picsum.photos/id/19/1200/1200")!,
        URL(string: "https://picsum.photos/id/20/1200/1200")!,
        URL(string: "https://picsum.photos/id/21/1200/1200")!,
        URL(string: "https://picsum.photos/id/22/1200/1200")!,
        URL(string: "https://picsum.photos/id/23/1200/1200")!,
        URL(string: "https://picsum.photos/id/24/1200/1200")!,
        URL(string: "https://picsum.photos/id/25/1200/1200")!,
        URL(string: "https://picsum.photos/id/26/1200/1200")!,
        URL(string: "https://picsum.photos/id/27/1200/1200")!,
        URL(string: "https://picsum.photos/id/28/1200/1200")!,
        URL(string: "https://picsum.photos/id/29/1200/1200")!,
        URL(string: "https://picsum.photos/id/30/1200/1200")!,
        URL(string: "https://picsum.photos/id/31/1200/1200")!,
        URL(string: "https://picsum.photos/id/32/1200/1200")!,
        URL(string: "https://picsum.photos/id/33/1200/1200")!,
        URL(string: "https://picsum.photos/id/34/1200/1200")!,
        URL(string: "https://picsum.photos/id/35/1200/1200")!,
        URL(string: "https://picsum.photos/id/36/1200/1200")!
    ]
    
    init() {
        // URL 개수에 맞게 데이터 배열 초기화
        neoImageData = Array(repeating: 0, count: testImageURLs.count)
        kingfisherData = Array(repeating: 0, count: testImageURLs.count)
    }
    
    func initialize(){
        neoImageData = Array(repeating: 0, count: testImageURLs.count)
        kingfisherData = Array(repeating: 0, count: testImageURLs.count)
        neoImageLoadCompleted = false
        kingfisherLoadCompleted = false
    }
    
    // 캐시 비우기
    func clearCache() {
        Task {
            try await ImageCache.shared.clearCache()
            print("NeoImage cleared")
        }
        
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        
        initialize()
        
        print("Cache Cleared")
    }
    
    private func checkNeoImageCompletion() {
        // 그리드에 표시할 이미지의 모든 값이 0이 아닌지 확인
        let relevantData = Array(neoImageData.prefix(gridImageCount))
        let allLoaded = !relevantData.contains(where: { $0 == 0 })
        
        // 모든 이미지가 로드되었고 아직 통계가 계산되지 않았다면
        if allLoaded && !neoImageLoadCompleted {
            calculateNeoImageStats()
            neoImageLoadCompleted = true // 완료 상태를 true로 설정
        }
    }

    private func checkKingfisherCompletion() {
        // 그리드에 표시할 이미지의 모든 값이 0이 아닌지 확인
        let relevantData = Array(kingfisherData.prefix(gridImageCount))
        let allLoaded = !relevantData.contains(where: { $0 == 0 })
        
        // 모든 이미지가 로드되었고 아직 통계가 계산되지 않았다면
        if allLoaded && !kingfisherLoadCompleted {
            calculateKingfisherStats()
            kingfisherLoadCompleted = true // 완료 상태를 true로 설정
        }
    }
    
    private func calculateNeoImageStats() {
        // 그리드에 표시된 이미지만 고려
        let validTimes = Array(neoImageData.prefix(gridImageCount)).filter { $0 > 0 }
        
        if !validTimes.isEmpty {
            neoImageAverageTime = validTimes.reduce(0, +) / Double(validTimes.count)
            neoImageMinTime = validTimes.min() ?? 0
            neoImageMaxTime = validTimes.max() ?? 0
            print("""
                  NeoImage
                  평균: \(String(format: "%.3f",neoImageAverageTime)), 최단소요: \(String(format: "%.3f",neoImageMinTime)), 최장소요: \(String(format: "%.3f",neoImageMaxTime)),
                  """)
        }
    }
    
    // Kingfisher 통계 계산
    private func calculateKingfisherStats() {
        // 그리드에 표시된 이미지만 고려
        let validTimes = Array(kingfisherData.prefix(gridImageCount)).filter { $0 > 0 }
        
        if !validTimes.isEmpty {
            kingfisherAverageTime = validTimes.reduce(0, +) / Double(validTimes.count)
            kingfisherMinTime = validTimes.min() ?? 0
            kingfisherMaxTime = validTimes.max() ?? 0
            print("""
                  Kingfisher
                  평균: \(String(format: "%.3f", kingfisherAverageTime)), 최단소요: \(String(format: "%.3f",kingfisherMinTime)), 최장소요: \(String(format: "%.3f",kingfisherMaxTime)),
                  """)
        }
    }
}
