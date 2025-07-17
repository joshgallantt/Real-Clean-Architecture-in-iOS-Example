//
//  FavoritesScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

struct FavoritesScreenView: View {
    @ObservedObject var viewModel: FavoritesScreenViewModel

    var body: some View {
        VStack {
            Text("Favorites Screen")
            Button("Open Favorites Detail") {
                viewModel.openDetail(id: UUID())
            }
            Button("Go to Cart Detail") {
                viewModel.goToCartDetail(id: UUID())
            }
        }
    }
}

struct FavoritesDetailScreenView: View {
    let id: UUID
    var body: some View {
        Text("Favorites Detail for \(id.uuidString)")
    }
}
