import SwiftUI

struct AuthSheetHeader: View {
    let header: AuthHeader

    init(_ header: AuthHeader) {
        self.header = header
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: header.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 4) {
                Text(header.title)
                    .font(.title2.bold())
                Text(header.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
