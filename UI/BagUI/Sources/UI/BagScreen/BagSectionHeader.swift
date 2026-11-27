import SwiftUI

/// The description sits with the heading and the action rather than under the rows, so a shopper
/// reads what a section is and what they can do about it before they read its contents — and does
/// not have to scroll past the rows to find out why they are there.
struct BagSectionHeader<Trailing: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let description: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)

                Spacer()

                trailing
                    .font(.footnote.weight(.semibold))
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }
}
