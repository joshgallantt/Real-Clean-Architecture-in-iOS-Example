//
//  UserSession.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation
import Combine

protocol UserSessionProtocol: AnyObject {
    var user: User? { get }
    var authToken: AuthToken? { get }
    var isLoggedIn: Bool { get }
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }

    func setUser(_ user: User, token: AuthToken)
    func clear()
}

final class UserSession: ObservableObject, UserSessionProtocol {
    @Published private(set) var user: User?
    @Published private(set) var authToken: AuthToken?

    private var expiryTimer: DispatchSourceTimer?

    var isLoggedIn: Bool {
        guard let token = authToken, !token.isExpired else { return false }
        return true
    }

    var isLoggedInPublisher: AnyPublisher<Bool, Never> {
        $authToken
            .map { token in
                guard let token = token else { return false }
                return !token.isExpired
            }
            .eraseToAnyPublisher()
    }

    func setUser(_ user: User, token: AuthToken) {
        self.user = user
        self.authToken = token
        scheduleExpiry(for: token)
    }

    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.user = nil
            self?.authToken = nil
        }
        cancelExpiryTimer()
    }

    private func scheduleExpiry(for token: AuthToken) {
        cancelExpiryTimer()

        let interval = token.expiresAt.timeIntervalSinceNow

        guard interval > 0 else {
            clear()
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler { [weak self] in
            self?.clear()
        }
        timer.resume()
        expiryTimer = timer
    }
    
    private func cancelExpiryTimer() {
        expiryTimer?.cancel()
        expiryTimer = nil
    }

}

