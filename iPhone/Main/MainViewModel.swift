//
//  MainViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 24/07/2026.
//

import Combine
import Foundation
import Session

@MainActor
final class MainViewModel: ObservableObject {
    enum Phase: Hashable {
        case splash
        case welcome
        case onboarding
        case main
    }

    @Published private(set) var phase: Phase = .splash

    private let getSession: GetSessionUseCase

    private let splashDuration: Duration = .seconds(1.2)

    /// A beat between the authentication sheet leaving and the app changing underneath, so
    /// the two read as one thing finishing and the next beginning rather than as a single
    /// lurch.
    private let settleAfterAuthentication: Duration = .milliseconds(300)

    init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    func onAppear() async {
        guard phase == .splash else { return }
        try? await Task.sleep(for: splashDuration)
        guard phase == .splash else { return }
        phase = getSession().isLoggedIn ? .main : .welcome
    }

    func continueAsGuest() {
        phase = .main
    }

    /// Called when the Welcome screen's authentication flow has finished *and* its sheet has
    /// gone — not when the session changed, which happens a few seconds earlier while the
    /// user is still reading the confirmation.
    func authenticationFinished() {
        Task {
            try? await Task.sleep(for: settleAfterAuthentication)
            phase = .main
        }
    }
}
