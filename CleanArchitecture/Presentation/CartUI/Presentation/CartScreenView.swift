//
//  CartScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct CartScreenView: View {
    @ObservedObject var viewModel: CartScreenViewModel
    let navigation: CartNavigation

    public var body: some View {
        VStack {
            Text("Cart")
            Button("Open Cart Detail") {
                let id = UUID()
                viewModel.didSelectCartDetail(id: id)
                navigation.openCartDetail(id: id)
            }
            Button("Go to Home Detail") {
                let id = UUID()
                viewModel.didSelectGoToHomeDetail(id: id)
                navigation.openHomeDetail(id: id)
            }
        }
    }
}


public struct CartDetailScreenView: View {
    let id: UUID
    public var body: some View {
        Text("Cart Detail for \(id.uuidString)")
    }
}
