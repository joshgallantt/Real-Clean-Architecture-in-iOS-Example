//
//  DefaultAuthPresenter.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 25/07/2026.
//

import Combine
import Session
import LoginUI

/// Centralises the "authentication-gated action" flow: a feature awaits authentication;
/// if the user is a guest we present the auth flow and resume the caller once it resolves.
@MainActor
final class DefaultAuthPresenter: ObservableObject, AuthPresenting {
    @Published var isPresentingAuth = false

    // A list, not a single slot: a guest can trigger more than one gated action (e.g.
    // wishlisting two different products) before the auth sheet is resolved, and none of
    // those callers should be left suspended forever.
    private var pendingContinuations: [CheckedContinuation<Bool, Never>] = []
    private let requireAuthenticationUseCase: RequireAuthenticationUseCase

    init(requireAuthenticationUseCase: RequireAuthenticationUseCase) {
        self.requireAuthenticationUseCase = requireAuthenticationUseCase
    }

    func requireAuthentication() async -> Bool {
        if await requireAuthenticationUseCase() {
            return true
        }
        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)
            isPresentingAuth = true
        }
    }

    /// Called by the auth flow on a successful login / create account.
    func completeAuthentication() {
        isPresentingAuth = false
        let continuations = pendingContinuations
        pendingContinuations = []
        continuations.forEach { $0.resume(returning: true) }
    }

    /// Called when the auth flow is dismissed without authenticating.
    func cancelAuthentication() {
        let continuations = pendingContinuations
        pendingContinuations = []
        continuations.forEach { $0.resume(returning: false) }
    }
}
