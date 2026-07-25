import SheetUI

public struct SheetUIDI {
    public let presenter: SheetPresenter

    @MainActor
    public init() {
        self.presenter = SheetPresenter()
    }
}
