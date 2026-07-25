//
//  AuthGate.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 25/07/2026.
//

/// A gate that features call to run an authentication-restricted action. If the user is
/// already authenticated the action runs immediately; otherwise the auth flow is presented
/// and the action is re-run once the user logs in or creates an account.
@MainActor
public protocol AuthGate: AnyObject {
    func requireAuthentication(_ action: @escaping () -> Void)
}
