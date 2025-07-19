//
//  CartDetailScreenView.swift
//  CartUI
//
//  Created by Josh Gallant on 19/07/2025.
//


import SwiftUI

public struct CartDetailScreenView: View {
    let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    public var body: some View {
        Text("Cart Detail for \(id.uuidString)")
    }
}
