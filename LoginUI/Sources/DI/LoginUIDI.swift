//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import LoginUI
import UserDI

public struct LoginUIDI {
    private let userDI: UserDI

    public init(userDI: UserDI) {
        self.userDI = userDI
    }

    @MainActor
    public func makeLoginScreenViewModel() -> LoginScreenViewModel {
        LoginScreenViewModel(userLogin: userDI.userLoginUseCase)
    }
    
    @MainActor
    public func mainView() -> some View {
        LoginScreenView(viewModel: makeLoginScreenViewModel())
    }
}
