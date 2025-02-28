import SwiftUI

// Font 확장 - 앱에서 사용할 텍스트 스타일
extension Font {
    static let _headline = Font.system(size: 20, weight: .bold)
    static let _title1 = Font.system(size: 18, weight: .semibold)
    static let _title2 = Font.system(size: 16, weight: .semibold)
    static let _subtitle1 = Font.system(size: 16, weight: .medium)
    static let _subtitle2 = Font.system(size: 14, weight: .medium)
    static let _body1 = Font.system(size: 16, weight: .regular)
    static let _body2 = Font.system(size: 14, weight: .regular)
}
