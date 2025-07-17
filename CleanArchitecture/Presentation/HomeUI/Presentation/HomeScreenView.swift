//
//  HomeScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import Combine

struct HomeScreenView: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    
    public init(viewModel: HomeScreenViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        VStack {
            Text("Home Screen")
            Button("Open Home Detail") {
                viewModel.openDetail(id: UUID())
            }
            Button("Go to Favorites Detail") {
                viewModel.goToFavoritesDetail(id: UUID())
            }
        }
    }
}

struct HomeDetailScreenView: View {
    let id: UUID
    var body: some View {
        Text("Home Detail for \(id.uuidString)")
    }
}
