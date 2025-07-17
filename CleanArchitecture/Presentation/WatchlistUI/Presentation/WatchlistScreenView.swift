//
//  CartScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI


public struct CartScreenView: View {
    @ObservedObject var viewModel: CartScreenViewModel

    public init(viewModel: CartScreenViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            Text("Cart")
            Button("Open Cart Detail") {
                viewModel.openDetail(id: UUID())
            }
            Button("Go to Home Detail") {
                viewModel.goToHomeDetail(id: UUID())
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
