//
//  SplashView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 24/07/2026.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                ProgressView()
            }
        }
    }
}
