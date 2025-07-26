//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import UserDomain
import LoginPresentation

public struct LoginUIDI {
    let userLogin: UserLoginUseCase

    public init(userLogin: UserLoginUseCase) {
        self.userLogin = userLogin
    }

    @MainActor
    public func makeLoginScreenViewModel() -> LoginScreenViewModel {
        LoginScreenViewModel(userLogin: userLogin)
    }
    
    @MainActor
    public func mainView() -> some View {
        LoginScreenView(viewModel: makeLoginScreenViewModel())
    }
}
