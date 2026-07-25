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

    // A queue, not a single slot: a guest can trigger more than one gated action
    // (e.g. wishlisting two different products) before the auth sheet is resolved,
    // and none of those requests should be silently dropped.
    private var pendingActions: [() -> Void] = []
    private let getSession: GetSessionUseCase

    init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    /// Runs `action` immediately when authenticated, otherwise queues it behind the auth flow.
    func requireAuthentication(_ action: @escaping () -> Void) {
        if getSession().isLoggedIn {
            action()
        } else {
            pendingActions.append(action)
            isPresentingAuth = true
        }
    }

    /// Called by the auth flow on a successful login / create account.
    func completeAuthentication() {
        isPresentingAuth = false
        let actions = pendingActions
        pendingActions = []
        actions.forEach { $0() }
    }

    /// Called when the auth flow is dismissed without authenticating.
    func cancelAuthentication() {
        pendingActions = []
    }
}
