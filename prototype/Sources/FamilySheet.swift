import SwiftUI

/// Household, members and account. Leaving and deleting are as easy to find as joining.
struct FamilySheet: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isInvitePresented = false
    @State private var isDeleteConfirming = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Ev adı", value: store.householdName)
                }

                Section {
                    ForEach(store.members) { member in
                        HStack(spacing: 12) {
                            MemberAvatar(member: member)
                            Text(member == store.me ? "\(member.name) (siz)" : member.name)
                            Spacer()
                            Text(member.role)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Üye davet et", systemImage: "person.badge.plus") {
                        isInvitePresented = true
                    }
                } header: {
                    Text("Üyeler")
                } footer: {
                    Text("Ortak liste, stok ve ortak harcamalar tüm üyelerle paylaşılır. Kişisel harcamalar paylaşılmaz.")
                }

                Section {
                    Toggle(isOn: Bindable(store).hidesAmounts) {
                        Label("Tutarları gizle", systemImage: "eye.slash")
                    }
                } footer: {
                    Text("Bütçe ve harcama tutarları bulanıklaşır. Telefon aile içinde ortak kullanılıyorsa ya da başkalarının yanındaysanız işe yarar.")
                }

                Section("Uygulama") {
                    NavigationLink { Text("Bildirim ayarları") } label: {
                        Label("Bildirimler", systemImage: "bell.badge")
                    }
                    NavigationLink { Text("Kategoriler ve limitler") } label: {
                        Label("Bütçe ve kategoriler", systemImage: "slider.horizontal.3")
                    }
                }

                Section {
                    Button("Çıkış yap", systemImage: "rectangle.portrait.and.arrow.right") {}
                    Button("Hesabı sil", systemImage: "trash", role: .destructive) {
                        isDeleteConfirming = true
                    }
                    .confirmationDialog(
                        "Hesabınız ve kişisel verileriniz silinsin mi?",
                        isPresented: $isDeleteConfirming, titleVisibility: .visible
                    ) {
                        Button("Hesabı sil", role: .destructive) {}
                    } message: {
                        Text("Ortak liste ve ortak harcamalar evde kalır; sizin adınız “eski üye” olarak görünür.")
                    }
                }
            }
            .navigationTitle("Aile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
            .sheet(isPresented: $isInvitePresented) {
                InviteSheet()
                    .presentationDetents([.medium])
            }
        }
    }
}

private struct InviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let code = "482 913"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Bu kodu eve katılacak kişiyle paylaşın.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text(code)
                    .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
                    .accessibilityLabel("Davet kodu \(code)")
                Text("72 saat geçerli · tek kullanımlık")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ShareLink(item: "Homeras'ta evimize katıl: \(code)") {
                    Label("Kodu paylaş", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Üye davet et")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}
