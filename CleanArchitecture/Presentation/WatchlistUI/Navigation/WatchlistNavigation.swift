//
//  CartNavigation.swift
//

import Foundation

public protocol CartNavigation: AnyObject {
    func openCartDetail(id: UUID)
    func openHomeDetail(id: UUID)
}
