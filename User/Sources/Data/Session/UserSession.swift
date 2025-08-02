//
//  UserSession.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation
import Combine
import UserDomain

@MainActor
public protocol UserSession: AnyObject {
    var user: User? { get }
    var authToken: AuthToken? { get }
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}

@MainActor
public final class DefaultUserSession: UserSession {
    public private(set) var user: User?
    public private(set) var authToken: AuthToken?
    private var expiryTimer: DispatchSourceTimer?
    private let isLoggedInSubject: CurrentValueSubject<Bool, Never>

    public init() {
        self.isLoggedInSubject = CurrentValueSubject(false)
    }

    public var isLoggedInPublisher: AnyPublisher<Bool, Never> {
        isLoggedInSubject.eraseToAnyPublisher()
    }

    public func setUser(_ user: User, token: AuthToken) {
        self.user = user
        self.authToken = token
        isLoggedInSubject.send(true)
        scheduleExpiry(for: token)
    }

    public func clear() {
        self.user = nil
        self.authToken = nil
        isLoggedInSubject.send(false)
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
