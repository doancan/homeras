# Uygulama iskeleti ve Alışveriş dilimi — uygulama planı

> Yürütme: görev görev, her görev kendi test döngüsüyle (TDD). Adımlar `- [ ]` ile işaretlenir.

**Amaç:** Onaylı tasarımın (app-experience.md) ilk dikey dilimini ürüne taşımak: sekme iskeleti,
sağ üstte tek vurgulu "+", reyon sırasına göre gruplu ortak alışveriş listesi, sepete alma,
silme ve "Geri al" bildirimi — gerçek veriyle, Supabase üzerinden, iki üye arasında.

**Mimari:** Mevcut modül yapısı korunur (ADR-0001). Core'a yeni alanlar ve port metotları,
SupabaseBackend'e karşılıkları, ShoppingFeature'a onaylı ekran, App'e `TabView` iskeleti eklenir.
Tasarım bileşenleri DesignSystem'e taşınır. Şema değişikliği migration + pgTAP ile (ADR-0003/0004).

**Teknoloji:** Swift 6.4, SwiftUI (iOS 26 taban, iOS 27 SDK), Supabase (Postgres 17, PostgREST).

**Spec:** `docs/product/features/app-experience.md`; FR-040, FR-041, FR-044 hariç (offline ayrı plan).
**Referans kod:** git etiketi `ux-prototype-v1` → `prototype/Sources/ShoppingView.swift`,
`Components.swift`, `PrototypeApp.swift` (örnek veri ve `Demo` parametreleri taşınmaz).

## Genel kısıtlar

- Minimum iOS 26.0; iOS 27 API'leri `#available(iOS 27.0, *)` ve iOS 26 karşılığıyla (ADR-0007).
- Liquid Glass yalnızca fonksiyonel katmanda; satır ve kartlar düz yüzey.
- Vurgu `#254940` (açık) / `#4FA58C` (koyu); uyarı `#B8662E` / `#EBA36D`.
- Tüm metinler modül String Catalog'unda, tr + en; isimlerden sonra Türkçe ek üretilmez.
- Arama ve eşleştirme Türkçe i/ı/İ/I farkına duyarsız (`searchKey`).
- Her yeni tabloya/kolona RLS ve "başka ev erişemez / anon erişemez" pgTAP testi.

## İnceleme odağı (testle bağlanacak riskler)

1. İki üye aynı öğeyi aynı anda sepete alır/geri alır → son yazan kazanır, öğe kaybolmaz (Görev 2 pgTAP + Görev 3 entegrasyon).
2. Silinen öğeyi diğer üye işaretlemeye çalışır → `notFound`, liste yenilenir, çökme yok (Görev 3, 4).
3. Ağ yokken sepete alma → görünür geri dönüş + hata mesajı, sessiz kayıp yok (Görev 4).
4. Başka evin öğesini işaretleme/silme → `forbidden` (Görev 2 pgTAP, Görev 3).
5. "Geri al" 5 sn içinde iki kez basılır → tek geri alma (Görev 4).

---

### Görev 1: DesignSystem temelleri ve Türkçe arama anahtarı

**Dosyalar:**
- Oluştur: `Packages/AppModules/Sources/Core/SearchKey.swift`, `Sources/DesignSystem/{IconBadge,MemberAvatar,ContentSwitcherStyle,UndoToast}.swift`, `Sources/DesignSystem/Resources/Colors.xcassets` (Warning, Mint)
- Test: `Tests/CoreTests/SearchKeyTests.swift`, `Tests/DesignSystemTests/DesignSystemTests.swift`

**Arayüzler — üretir:**
- `extension String { var searchKey: String; func matchesSearch(_ query: String) -> Bool }` (Core)
- `IconBadge(symbol: String, tint: Color)`, `MemberAvatar(initial: String, color: Color)`, `View.contentSwitcherStyle()`, `UndoToast(title: String, onUndo: () -> Void)`, `Color.homerasWarning`, `Color.homerasMint` (DesignSystem)

- [ ] Test: `"HDMI kablo".matchesSearch("hdmi")`, `"KILIF".matchesSearch("kılıf")`, `"İzmir".matchesSearch("izmir")`, `"Süt".matchesSearch("")` → hepsi `true`; `"Süt".matchesSearch("ekmek")` → `false`
- [ ] Çalıştır `make test-packages` → FAIL (tip yok)
- [ ] `searchKey`: ı/İ/I → i, sonra `.caseInsensitive, .diacriticInsensitive` folding, `en_US_POSIX`
- [ ] Bileşenler prototipteki karşılıklarından; `UndoToast` metni çağıranın catalog'undan gelir
- [ ] DesignSystem catalog'una `action.undo` ("Geri al" / "Undo") ve test listesine ekle
- [ ] `make test-packages` → PASS · Commit: `feat(design): add shared components and Turkish-insensitive search`

### Görev 2: Şema — kategori, not, sepete alma, silme

**Dosyalar:**
- Oluştur: `supabase/migrations/20261121090000_shopping_items_category_and_cart.sql`
- Test: `supabase/tests/database/shopping_cart.test.sql`

**Arayüzler — üretir:** `shopping_items.category text not null default 'Diğer'` (1–40, trim),
`note text` (≤ 60), `in_cart_at timestamptz null`, `in_cart_by uuid null` (trigger `auth.uid()` atar);
GRANT `update (category, note, in_cart_at)`, `delete` üyelere; politikalar `shopping_items_update_member`, `shopping_items_delete_member`.

- [ ] pgTAP: üye sepete alır (`in_cart_at` set, `in_cart_by` = çağıran); üye geri alır (null); başka ev üyesi update → 0 satır / 42501; başka ev delete → etkisiz; anon update/delete → 42501; istemci `in_cart_by`'yi yazamaz (kolon GRANT'ı yok → 42501); boş kategori → 23514
- [ ] `make verify-db` → FAIL
- [ ] Migration (kolonlar `add column ... default` ile geriye uyumlu), trigger `private.set_in_cart_by()`, politikalar ve GRANT'lar
- [ ] `make verify-db` → PASS · Commit: `feat(db): add shopping item category, note and cart state`

### Görev 3: Core ve Supabase adapter

**Dosyalar:**
- Değiştir: `Sources/Core/ShoppingItem.swift`, `Sources/Core/Ports.swift`, `Sources/SupabaseBackend/{Rows,SupabaseShoppingListRepository}.swift`
- Oluştur: `Sources/Core/ShoppingAisle.swift`
- Test: `Tests/CoreTests/ShoppingAisleTests.swift`, `Tests/SupabaseBackendTests/RowMappingTests.swift`, `Tests/SupabaseBackendIntegrationTests/WalkingSkeletonTests.swift`

**Arayüzler — üretir:**
- `ShoppingItem` + `aisle: ShoppingAisle`, `note: String?`, `inCartAt: Date?`, `addedBy: UserID?`; `var isInCart: Bool`
- `enum ShoppingAisle: String, CaseIterable { produce = "Manav", dairy = "Süt ve kahvaltı", bakery = "Fırın", pantry = "Kiler", cleaning = "Temizlik", personalCare = "Kişisel bakım", other = "Diğer" }` — `CaseIterable` sırası = mağaza yürüyüş sırası
- `ShoppingItemDraft(name:aisle:note:)`
- `ShoppingListRepository`: `setInCart(_ id: ShoppingItemID, _ inCart: Bool, household: HouseholdID) async throws(RepositoryError) -> ShoppingItem`, `remove(_ id: ShoppingItemID, household: HouseholdID) async throws(RepositoryError)`
- `RepositoryError.notFound` (yeni durum; DesignSystem mesajı "Bu öğe artık listede değil.")

- [ ] Testler: bilinmeyen kategori metni `.other`'a düşer; satır eşlemesi `in_cart_at` → `isInCart`; entegrasyon: sepete al/geri al, sil, başka kullanıcı `forbidden`, silinmiş öğeyi işaretleme `notFound`
- [ ] FAIL'i gör → uygula (`setInCart` PATCH `in_cart_at = now()|null`; dönen 0 satır → `notFound`) → `make test-packages` ve `make verify-integration` PASS
- [ ] Commit: `feat(shopping): support aisles, cart state and removal end to end`

### Görev 4: ShoppingFeature — onaylı ekran

**Dosyalar:**
- Değiştir: `Sources/ShoppingFeature/{ShoppingListModel,ShoppingListView}.swift`, `Resources/Localizable.xcstrings`
- Oluştur: `Sources/ShoppingFeature/AddShoppingItemSheet.swift`
- Test: `Tests/ShoppingFeatureTests/ShoppingListModelTests.swift`

**Arayüzler — üretir:** `ShoppingListModel.sections: [(ShoppingAisle, [ShoppingItem])]` (yalnızca sepette olmayanlar, aisle sırasıyla), `cart: [ShoppingItem]`, `toggleCart(_:) async`, `remove(_:) async`, `undoLastAdd() async`, `lastAdded: ShoppingItem?`

- [ ] Model testleri: gruplar `ShoppingAisle.allCases` sırasında; sepete alma iyimser (anında taşınır), hata gelirse geri döner ve `actionError` set olur; `notFound` → öğe listeden düşer; "Geri al" ikinci kez çağrıldığında etkisiz; çift dokunuşta tek istek
- [ ] FAIL → uygula → PASS
- [ ] View: prototipteki düzen (gruplu bölümler, "Sepette · N", satıra dokununca sepete, kaydırınca sil, ekleyen avatarı), loading/empty/error, VoiceOver değerleri ("Sepette"/"Alınacak"), en büyük yazıda dikey yerleşim
- [ ] `AddShoppingItemSheet`: ad (1–120), reyon çipleri, not; ekle düğmesi altta; kayıttan sonra `UndoToast`
- [ ] Commit: `feat(shopping): approved shopping list with aisles, cart and undo`

### Görev 5: Uygulama iskeleti

**Dosyalar:**
- Değiştir: `App/RootView.swift`, `App/RootModel.swift`, `App/Localizable.xcstrings`
- Oluştur: `App/MainTabs.swift`, `App/FamilySheet.swift`
- Test: `AppTests/RootModelTests.swift`

**Arayüzler — tüketir:** Görev 4'ün `ShoppingListView`, `AddShoppingItemSheet`.
**Üretir:** `MainTabs(model:)` — şimdilik yalnızca gerçek içeriği olan sekmeler: **Alışveriş**; sağ üstte `+` (Alışveriş ekleme sheet'i) ve Aile düğmesi (`FamilySheet`: üyeler ve çıkış; hesap silme FR-007 dilimiyle eklenir). Diğer sekmeler kendi dilimleriyle eklenir (taslak sekme yok).

- [ ] RootModel testi: oturum + ev varsa ekran `.main` olur ve alışveriş modeli aynı evi kullanır
- [ ] FAIL → uygula → PASS (`make verify`)
- [ ] Gerçek cihazda kontrol: iki hesapla (e-posta OTP, yerel Supabase) ekleme, sepete alma, silme, geri alma; açık/koyu, en büyük yazı; iOS 27.2 (iOS 26: README'de "Doğrulanmadı")
- [ ] Commit: `feat(app): tab shell with trailing add action and family sheet`

### Görev 6: Docs ve doğrulama

- [ ] `overview.md` modül tablosu ve "Kalıcı veri" (yeni kolonlar, politikalar, indeks kararı: `(household_id, in_cart_at)` gerekmez — liste ≤ 50 sayfalı, mevcut indeks yeterli)
- [ ] `requirements.md`: FR-040 Tamamlandı, FR-041 Tamamlandı; README "Mevcut durum" ve "Sonraki adımlar" (Plan 2: Aile ve davet)
- [ ] `make verify`, `make verify-db`, `make verify-integration`, `make verify-security` → hepsi yeşil; sonuçlar rapora
- [ ] Commit: `docs: record the shopping slice and app shell`

## Sonraki planlar (ayrı dokümanlar)

2. Aile ve davet (FR-004…FR-007) · 3. Bugün dashboard'u · 4. Finans defteri (ADR-0009) ·
5. Stok ve eşyalar · 6. Offline senkronizasyon (ADR-0005) · 7. Bildirimler (FR-071)
