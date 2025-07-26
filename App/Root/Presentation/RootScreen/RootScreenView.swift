//
//  RootScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 19/07/2025.
//

import SwiftUI

struct RootScreenView: View {
    @ObservedObject var viewModel: RootScreenViewModel
    let loginView: AnyView
    let main: AnyView

    init(
        viewModel: RootScreenViewModel,
        loginView: some View,
        mainView: some View
    ) {
        self.viewModel = viewModel
        self.loginView = AnyView(loginView)
        self.main = AnyView(mainView)
    }

    var body: some View {
        switch viewModel.path {
        case .login:
            loginView
        case .main:
            main
        }
    }
}
