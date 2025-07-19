//
//  HomeDetailScreenView.swift
//  HomeUI
//
//  Created by Josh Gallant on 19/07/2025.
//


import SwiftUI

public struct HomeDetailScreenView: View {
    let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    public var body: some View {
        Text("Home Detail for \(id.uuidString)")
    }
}
