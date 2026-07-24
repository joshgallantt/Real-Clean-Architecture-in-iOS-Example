//
//  SessionStore.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation
import Combine
import Session

@MainActor
public protocol SessionStore: AnyObject, Sendable {
    var session: Session { get }
    var sessionPublisher: AnyPublisher<Session, Never> { get }
    var authToken: AuthToken? { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}

@MainActor
public final class DefaultSessionStore: SessionStore {
    public private(set) var authToken: AuthToken?
    private var expiryTimer: DispatchSourceTimer?
    private let sessionSubject: CurrentValueSubject<Session, Never>

    public init() {
        self.sessionSubject = CurrentValueSubject(.guest)
    }

    public var session: Session {
        sessionSubject.value
    }

    public var sessionPublisher: AnyPublisher<Session, Never> {
        sessionSubject.eraseToAnyPublisher()
    }

    public func setUser(_ user: User, token: AuthToken) {
        self.authToken = token
        sessionSubject.send(.authenticated(user))
        scheduleExpiry(for: token)
    }

    public func clear() {
        self.authToken = nil
        sessionSubject.send(.guest)
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
