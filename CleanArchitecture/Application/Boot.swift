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
        
    }

    var body: some Scene {
        WindowGroup {
            Injector.shared.bootUIDI.mainView()
        }
    }
}

