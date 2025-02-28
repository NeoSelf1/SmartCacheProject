import SwiftUI

struct ProfileView: View {
    @State private var username: String = "John Doe"
    @State private var email: String = "john.doe@example.com"
    
    var body: some View {
        VStack(spacing: 0) {
//            CustomHeader(title: "My Profile")
            
            ScrollView {
                VStack(spacing: 24) {
                    // 프로필 헤더
                    profileHeader
                    
                    // 메뉴 섹션
                    menuSection
                }
                .padding(16)
            }
        }
    }
    
    // 프로필 헤더
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray60)
            
            // 사용자 정보
            VStack(spacing: 4) {
                Text(username)
                    .font(._headline)
                    .foregroundColor(.gray90)
                
                Text(email)
                    .font(._body1)
                    .foregroundColor(.gray60)
            }
            
            // 편집 버튼
            Button(action: {
                // 프로필 편집 기능 (실제 구현 시 추가)
            }) {
                Text("Edit Profile")
                    .font(._body1)
                    .foregroundColor(.red50)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red50, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 16)
    }
    
    // 메뉴 섹션
    private var menuSection: some View {
        VStack(spacing: 0) {
            Group {
                menuRow(icon: "bag", title: "My Orders") {
                    // 주문 내역 기능 (실제 구현 시 추가)
                }
                
                Divider()
                
                menuRow(icon: "creditcard", title: "Payment Methods") {
                    // 결제 수단 기능 (실제 구현 시 추가)
                }
                
                Divider()
                
                menuRow(icon: "location", title: "Delivery Addresses") {
                    // 배송지 관리 기능 (실제 구현 시 추가)
                }
                
                Divider()
                
                menuRow(icon: "bell", title: "Notifications") {
                    // 알림 설정 기능 (실제 구현 시 추가)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 메뉴 행 컴포넌트
    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray60)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(._body1)
                    .foregroundColor(.gray90)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray40)
            }
            .padding(16)
        }
    }
}
