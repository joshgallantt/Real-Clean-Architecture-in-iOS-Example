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
    private let observeSession: ObserveSessionUseCase
    private var cancellables = Set<AnyCancellable>()

    private let splashDuration: Duration = .seconds(1.2)

    init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
    }

    func onAppear() async {
        if cancellables.isEmpty {
            observeSession()
                .sink { [weak self] session in
                    guard let self, session.isLoggedIn else { return }
                    self.phase = .main
                }
                .store(in: &cancellables)
        }

        guard phase == .splash else { return }
        try? await Task.sleep(for: splashDuration)
        guard phase == .splash else { return }
        phase = getSession().isLoggedIn ? .main : .welcome
    }

    func continueAsGuest() {
        phase = .main
    }
}
