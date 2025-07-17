//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct LoginUIDI {
    let userLogin: UserLoginUseCase

    init(userLogin: UserLoginUseCase) {
        self.userLogin = userLogin
    }
    
    func mainView() -> some View {
        LoginScreenView(userLogin: userLogin)
    }
}
