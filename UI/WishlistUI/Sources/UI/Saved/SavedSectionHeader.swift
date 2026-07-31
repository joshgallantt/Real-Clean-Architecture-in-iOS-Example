import SwiftUI

/// The bag screen's heading, in the one other place this app groups things into sections: a label
/// in the section's colour, whatever the section can do about itself on the right, and a sentence
/// underneath saying what it is.
///
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the description
/// sits with the heading rather than under the contents, so a shopper reads what a section is
/// before they read what is in it — and, on a carousel, without scrolling sideways to find out.
struct SavedSectionHeader<Trailing: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let description: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)

                Spacer()

                trailing()
                    .font(.footnote.weight(.semibold))
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }
}

extension SavedSectionHeader where Trailing == EmptyView {
    init(title: String, icon: String, tint: Color, description: String) {
        self.init(title: title, icon: icon, tint: tint, description: description) { EmptyView() }
    }
}
