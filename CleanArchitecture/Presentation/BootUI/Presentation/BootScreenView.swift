//
//  BootScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import SwiftUI
import LoginUIDI

struct BootScreenView: View {
    @ObservedObject var bootViewModel: BootViewModel

    var body: some View {
        switch bootViewModel.path {
        case .login:
            return AnyView(Injector.shared.loginUIDI.mainView())
        case .main:
            return AnyView(Injector.shared.mainUIDI.mainView())
        }
    }
}
