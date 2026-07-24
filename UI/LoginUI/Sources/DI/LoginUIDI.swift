//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import LoginUI
import User

public struct LoginUIDI {
    private let userLogin: UserLoginUseCase

    public init(userLogin: UserLoginUseCase) {
        self.userLogin = userLogin
    }

    @MainActor
    public func makeLoginScreenViewModel() -> LoginScreenViewModel {
        LoginScreenViewModel(userLogin: userLogin)
    }
    
    @MainActor
    public func loginView() -> some View {
        LoginScreenView(viewModel: makeLoginScreenViewModel())
    }
}
