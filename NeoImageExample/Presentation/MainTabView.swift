
import SwiftUI

/// 앱의 메인 탭 기반 네비게이션 구조를 구현하는 뷰입니다.
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch(selectedTab) {
                case 0:
                    ImageLoadingPerformanceView()
                case 1:
                    FavoritesView()
                default:
                    ProfileView()
                }
                
                bottomTab
            }
        }
    }
    
    @ViewBuilder
    private var bottomTab: some View {
        let tabBarItems = [
            ("home", "Home"),
            ("star", "Favorites"),
            ("person", "Profile")
        ]
        
        ZStack {
            Rectangle()
                .fill(Color.gray10)
                .frame(height: 72)
            
            HStack(alignment: .center, spacing: 0) {
                ForEach(0..<tabBarItems.count, id: \.self) { index in
                    Button(action:{
                        withAnimation(.fastEaseInOut) { selectedTab = index }
                    } ) {
                        VStack(spacing: 4) {
                            Image(systemName: tabBarItems[index].0)
                                .foregroundColor(selectedTab == index ? .red50 : .gray90)
                                .font(.system(size: 22))
                            
                            Text(tabBarItems[index].1)
                                .font(._body1)
                                .foregroundColor(selectedTab == index ? .red50 : .gray90)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 72)
            .background(Color.gray10)
        }
    }
}

#Preview {
    MainTabView()
}
