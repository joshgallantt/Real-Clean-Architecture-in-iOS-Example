import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Order

@Suite("Order identifiers")
struct OrderIdentifierTests {
    @Test("A generated id is not empty")
    func generated() {
        #expect(OrderID().rawValue.isEmpty == false)
    }

    @Test("Two generated ids differ")
    func generatedAreUnique() {
        #expect(OrderID() != OrderID())
    }

    @Test("An id keeps what it was given")
    func rawValue() {
        #expect(OrderID(rawValue: "abc").rawValue == "abc")
    }

    @Test("Ids with the same value are the same id")
    func equality() {
        #expect(OrderID(rawValue: "a") == OrderID(rawValue: "a"))
        #expect(OrderID(rawValue: "a") != OrderID(rawValue: "b"))
    }

    @Test("A payment reference keeps what the processor called it")
    func paymentReference() {
        #expect(PaymentReference(rawValue: "txn_1").rawValue == "txn_1")
        #expect(PaymentReference(rawValue: "txn_1") == PaymentReference(rawValue: "txn_1"))
    }
}
