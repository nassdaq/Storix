import SwiftUI

public struct BeforeAfterView: View {
    public let onDone: () -> Void
    @State private var animateNumber = false

    public init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    public var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent)

            Text("You freed")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            Text("0 GB")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .scaleEffect(animateNumber ? 1.0 : 0.8)
                .opacity(animateNumber ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNumber)
                .onAppear { animateNumber = true }

            Text("Undo any time from Settings → Cleanup history.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    // MARK: TODO — share card render
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(width: 140, height: 36)
                        .background(Theme.surface)
                        .foregroundStyle(Theme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)

                Button(action: onDone) {
                    Text("Done")
                        .frame(width: 140, height: 36)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
