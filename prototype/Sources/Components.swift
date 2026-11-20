import SwiftUI

extension View {
    /// A picker that switches the content below it. iOS 27 draws it as tabs and VoiceOver
    /// announces it as tabs; iOS 26 falls back to the segmented look (ADR-0007).
    @ViewBuilder
    func contentSwitcherStyle() -> some View {
        if #available(iOS 27.0, *) {
            pickerStyle(.tabs)
        } else {
            pickerStyle(.segmented)
        }
    }
}

/// The one prominent action of every tab: always the trailing-most item in the navigation bar,
/// so it never covers content (functional layer, system glass).
struct QuickAddToolbarItem: ToolbarContent {
    let store: PrototypeStore

    var body: some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button("Hızlı ekle", systemImage: "plus") { store.isQuickAddPresented = true }
                .buttonStyle(.glassProminent)
                .accessibilityHint("Alışveriş, harcama ya da stok ekle")
        }
    }
}

extension View {
    /// Blurs a money amount while the household hides amounts; VoiceOver hears "gizli".
    func moneyPrivacy(_ isHidden: Bool) -> some View {
        // `.privacy` only redacts on the lock screen and in widgets; placeholder hides in-app.
        redacted(reason: isHidden ? .placeholder : [])
            .accessibilityValue(isHidden ? Text("gizli") : Text(""))
    }
}

/// A tinted SF Symbol tile used at the start of rows (content layer, no glass).
struct IconBadge: View {
    let symbol: String
    let tint: Color
    @ScaledMetric(relativeTo: .body) private var size = 32

    var body: some View {
        Image(systemName: symbol)
            .font(.callout.weight(.medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: .rect(cornerRadius: 8))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityHidden(true)
    }
}

struct MemberAvatar: View {
    let member: Member
    @ScaledMetric(relativeTo: .caption) private var size = 22

    var body: some View {
        Text(member.initial)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(member.color, in: .circle)
            // Decorative: capped so it never squeezes the text it sits next to.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityLabel(member.name)
    }
}

struct FamilyAvatars: View {
    let members: [Member]

    var body: some View {
        HStack(spacing: -6) {
            ForEach(members.prefix(3)) { member in
                MemberAvatar(member: member)
                    .overlay { Circle().stroke(Color(.systemBackground), lineWidth: 1.5) }
            }
        }
    }
}
