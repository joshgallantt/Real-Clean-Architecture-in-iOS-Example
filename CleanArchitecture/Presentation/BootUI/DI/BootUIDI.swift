//
//  BootUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import SwiftUI

public struct BootUIDI {
    private let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase

    init(observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase) {
        self.observeUserIsLoggedInUseCase = observeUserIsLoggedInUseCase
    }
    
    private func makeBootViewModel() -> BootViewModel {
        .init(observeUserLoggedIn: observeUserIsLoggedInUseCase)
    }

    func mainView() -> some View {
        BootScreenView(bootViewModel: makeBootViewModel())
    }
}
