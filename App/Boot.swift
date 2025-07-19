//
//  Boot.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import SwiftUI

@main
struct Boot: App {
    init() {
        Navigation.registerAllDestinations(using: Injector.shared)
    }

    var body: some Scene {
        WindowGroup {
            Injector.shared.rootUIDI.mainView()
        }
    }
}
