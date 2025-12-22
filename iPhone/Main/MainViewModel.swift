//
//  MainViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 22/12/2025.
//

import SwiftUI
import User
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    
    enum path: Hashable {
        case login, main
    }
    
    @Published var path: MainViewModel.path = .login
    private var cancellable: AnyCancellable?
    private let observeUserLoggedIn: ObserveUserIsLoggedInUseCase

    init(
        observeUserLoggedIn: ObserveUserIsLoggedInUseCase,
    ) {
        self.observeUserLoggedIn = observeUserLoggedIn
        self.path = .main
//        cancellable = observeUserLoggedIn.execute()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] loggedIn in
//                self?.path = loggedIn ? .main : .login
//            }
    }
}
