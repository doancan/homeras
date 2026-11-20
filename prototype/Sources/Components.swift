import SwiftUI

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
            .background(member.color.gradient, in: .circle)
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
