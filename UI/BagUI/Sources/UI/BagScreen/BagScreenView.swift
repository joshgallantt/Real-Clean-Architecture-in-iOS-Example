//
//  BagScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    let navigation: BagNavigation

    public init(viewModel: BagScreenViewModel, navigation: BagNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }
    
    public var body: some View {
        VStack {
            Text("Bag")
            Button("Open Bag Detail") {
                let id = UUID()
                viewModel.didSelectBagDetail(id: id)
            }
        }
    }
}
