//
//  BootUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import SwiftUI
import UserDomain

public struct BootUIDI {
    private let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol

    init(observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol) {
        self.observeUserIsLoggedInUseCase = observeUserIsLoggedInUseCase
    }
    
    private func makeBootViewModel() -> BootViewModel {
        BootViewModel(observeUserLoggedIn: observeUserIsLoggedInUseCase)
    }

    func mainView() -> some View {
        BootScreenView(bootViewModel: makeBootViewModel())
    }
}
