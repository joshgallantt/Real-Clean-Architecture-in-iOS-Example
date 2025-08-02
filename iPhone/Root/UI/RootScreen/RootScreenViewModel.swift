//
//  RootScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 19/07/2025.
//

import Foundation
import Combine
import UserDomain

@MainActor
final class RootScreenViewModel: ObservableObject {
    @Published var path: RootDestination
    private var cancellable: AnyCancellable?
    private let observeUserLoggedIn: ObserveUserIsLoggedInUseCase

    init(
        observeUserLoggedIn: ObserveUserIsLoggedInUseCase,
        initial: RootDestination = .main
    ) {
        self.observeUserLoggedIn = observeUserLoggedIn
        self.path = initial

        cancellable = observeUserLoggedIn.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                self?.path = loggedIn ? .main : .login
            }
    }
}
