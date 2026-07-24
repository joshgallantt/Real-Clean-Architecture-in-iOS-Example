//
//  BagUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import BagUI

public struct BagUIDI {
    private let navigation: BagNavigation

    public init(navigation: BagNavigation) {
        self.navigation = navigation
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(),
            navigation: navigation
        )
    }
}
