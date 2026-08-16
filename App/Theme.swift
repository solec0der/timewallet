import SwiftUI

/// Design tokens — one source of truth so every surface, radius and gap matches.
enum Theme {
    // Surfaces (dark-only app): base < card < tile, per Dark Mode base/elevated guidance.
    static let background = Color.black
    static let card = Color(white: 0.09)
    static let tile = Color(white: 0.14)

    static let cardRadius: CGFloat = 22
    static let tileRadius: CGFloat = 14

    static let screenPadding: CGFloat = 16
    static let rowPaddingV: CGFloat = 10
    static let rowPaddingH: CGFloat = 14
    static let sectionGap: CGFloat = 28
    static let headerToCardGap: CGFloat = 10

    static let tileSize: CGFloat = 40
}

/// Uppercase micro-label used for section captions (matches the reference app).
struct SectionCaption: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.footnote.weight(.semibold))
            .kerning(1.2)
            .foregroundStyle(.secondary)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.tile))
            Text(title)
                .font(.title3.weight(.semibold))
        }
    }
}

struct EmojiTile: View {
    let emoji: String
    var body: some View {
        Text(emoji)
            .font(.body)
            .frame(width: Theme.tileSize, height: Theme.tileSize)
            .background(RoundedRectangle(cornerRadius: 11).fill(Theme.tile))
    }
}

/// Subtle tinted fill button — the app's secondary action style.
struct SubtleButtonStyle: ButtonStyle {
    var tint: Color = .blue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: Theme.tileRadius).fill(tint.opacity(0.16)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct CardGroup<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
    }
}

struct InsetDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
            .padding(.leading, Theme.rowPaddingH + Theme.tileSize + 12)
    }
}
