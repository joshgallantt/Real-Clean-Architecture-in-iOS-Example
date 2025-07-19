//
//  BootViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Foundation
import SwiftUI
import Combine
import UserDomain

final class BootViewModel: ObservableObject {
    @Published var path: BootDestination
    private var cancellable: AnyCancellable?
    private let observeUserLoggedIn: ObserveUserIsLoggedInUseCaseProtocol

    init(
        observeUserLoggedIn: ObserveUserIsLoggedInUseCaseProtocol,
        initial: BootDestination = .main
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
