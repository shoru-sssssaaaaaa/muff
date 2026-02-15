import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool

    init() {
        self.hasCompletedOnboarding = AppSettings.shared.hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        AppSettings.shared.hasCompletedOnboarding = true
    }
}
