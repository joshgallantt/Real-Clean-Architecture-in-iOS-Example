//
//  HomeNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation

public protocol HomeNavigation: AnyObject {
    func openHomeDetail(id: UUID)
    func goToFavoritesDetail(id: UUID)
}
