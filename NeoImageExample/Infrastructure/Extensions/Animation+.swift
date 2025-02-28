import SwiftUI

extension Animation {
    static let fastEaseInOut = Animation.easeInOut(duration: 0.2)
    static let mediumSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
