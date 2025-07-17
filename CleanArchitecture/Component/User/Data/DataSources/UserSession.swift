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
    
    init() {
        print("[UserSession] Initilising")
    }

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
        print("[UserSession] Clearing session")
        DispatchQueue.main.async { [weak self] in
            self?.user = nil
            self?.authToken = nil
        }
        expiryTimer?.cancel()
        expiryTimer = nil
    }

    private func scheduleExpiry(for token: AuthToken) {
        expiryTimer?.cancel()
        expiryTimer = nil
        
        let interval = token.expiresAt.timeIntervalSinceNow
        print("[UserSession] Scheduling expiry timer")
        print("[UserSession] Token expires at: \(token.expiresAt) (now: \(Date()))")
        print("[UserSession] Calculated interval until expiry: \(interval) seconds")
        
        guard interval > 0 else {
            print("[UserSession] Token already expired, clearing session")
            clear()
            return
        }
        
        let clampedInterval = max(interval, 1)
        if interval != clampedInterval {
            print("[UserSession] Interval clamped to 1 second minimum")
        }
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + clampedInterval)
        timer.setEventHandler { [weak self] in
            print("[UserSession] Expiry timer fired, clearing session")
            self?.clear()
        }
        timer.resume()
        expiryTimer = timer
        
        print("[UserSession] Expiry timer scheduled to fire in \(clampedInterval) seconds")
    }
}

