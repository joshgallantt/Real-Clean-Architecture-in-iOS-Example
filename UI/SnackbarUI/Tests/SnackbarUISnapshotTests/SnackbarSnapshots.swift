import SnackbarUI
import SnapshotTesting
import SwiftUI
import Testing
@testable import SnackbarUIDI

@MainActor
@Test("A snackbar shows what happened and offers a way to undo it")
func aSnackbarOffersAWayToUndo() {
    let snackbar = SnackbarView(
        snackbar: Snackbar(
            title: "Added to Bag",
            message: "Kettle",
            icon: "bag.fill",
            action: SnackbarAction(label: "Undo", handler: {})
        ),
        onAction: {},
        onDismiss: {}
    )

    assertSnapshot(of: snackbar.frame(width: 390), as: .image(layout: .sizeThatFits))
}

@MainActor
@Test("A snackbar with nothing to undo simply says what happened")
func aSnackbarWithoutAnActionJustSaysWhatHappened() {
    let snackbar = SnackbarView(
        snackbar: Snackbar(title: "Off the List", message: "Kettle"),
        onAction: {},
        onDismiss: {}
    )

    assertSnapshot(of: snackbar.frame(width: 390), as: .image(layout: .sizeThatFits))
}
