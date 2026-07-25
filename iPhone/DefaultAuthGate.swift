//
//  DefaultAuthGate.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 25/07/2026.
//

import Combine
import Session
import AuthGate

/// Centralises the "authentication-gated action" flow: a feature asks to run some
/// action; if the user is a guest we present the auth flow and re-run the action once
/// they successfully log in or create an account.
@MainActor
final class DefaultAuthGate: ObservableObject, AuthGate {
    @Published var isPresentingAuth = false

    private var pendingAction: (() -> Void)?
    private let getSession: GetSessionUseCase

    init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    /// Runs `action` immediately when authenticated, otherwise defers it behind the auth flow.
    func requireAuthentication(_ action: @escaping () -> Void) {
        if getSession().isLoggedIn {
            action()
        } else {
            pendingAction = action
            isPresentingAuth = true
        }
    }

    /// Called by the auth flow on a successful login / create account.
    func completeAuthentication() {
        isPresentingAuth = false
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    /// Called when the auth flow is dismissed without authenticating.
    func cancelAuthentication() {
        pendingAction = nil
    }
}
