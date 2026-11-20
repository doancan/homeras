# Kod Konvansiyonları

Yalnızca bu projeye özgü, kontrol edilebilir kurallar. Araçların zaten zorladığı kurallar burada
tekrarlanmaz.

## Araçlar

| Amaç | Araç | Config |
|---|---|---|
| Format + lint | Toolchain'deki `swift format` (`lint --strict`) | `.swift-format` |
| Derleme sıkılığı | Swift 6 dil modu, uyarı = hata, `ExistentialAny`, `NonisolatedNonsendingByDefault` | `Packages/AppModules/Package.swift`, `project.yml` |
| Test | Swift Testing (`@Test`, `#expect`), pgTAP | — |
| Doğrulama | `make verify` · `make verify-db` · `make verify-integration` · `make verify-security` | `Makefile` |

## Dizin ve isimlendirme

- Dosya adı = içindeki ana tipin adı (`ShoppingListModel.swift`).
- Feature modülü: `Sources/<Ad>Feature/{<Ekran>Model.swift, <Ekran>View.swift, ModuleBundle.swift, Resources/Localizable.xcstrings}`.
- Adapter modülü: port başına bir tip (`Supabase<Port>`), wire formatları `Rows.swift`'te, hata eşleme `ErrorMapping.swift`'te.
- Migration: `supabase/migrations/<yyyyMMddHHmmss>_<snake_case>.sql`. pgTAP testi: `supabase/tests/database/<konu>.test.sql`.
- Kod tanımlayıcıları, yorumlar ve commit mesajları İngilizce; docs ve arayüz metinleri Türkçe + İngilizce.

## Katman kuralları

- `Core` yalnızca Foundation import eder. Domain değerleri doğrulanmış tiplerle taşınır
  (`HouseholdName`, `ShoppingItemName`, `EmailAddress`, `OneTimeCode`); ham `String` port sınırını geçmez.
- Feature modülleri yalnızca `Core` ve `DesignSystem` import eder. Backend'i port protokolü
  (`any ShoppingListRepository`) olarak init'te alır.
- View incedir: state ve aksiyonlar `@Observable` Model'dedir. View'da ağ ve veritabanı çağrısı yoktur.
- Hangi implementasyonun kullanılacağını yalnızca `App/AppServices.swift` bilir.
- SDK tipleri (`SupabaseClient`, `PostgrestError`) `SupabaseBackend` dışına sızmaz.

## Hata yönetimi

- Port metotları typed throws kullanır: `throws(RepositoryError)`, `throws(AuthError)`,
  doğrulama için `throws(ValidationError)`.
- SDK ve ağ hataları yalnızca `ErrorMapping`'de domain hatasına çevrilir. Sunucu mesajı kullanıcıya
  gösterilmez; `privacy: .private` ile loglanır.
- Model hatayı kendi `Failure`/`AddError` enum'unda tutar. Kullanıcı metni View'da
  `error.userMessage` (DesignSystem) ile üretilir.
- Auth hataları hesap varlığını sızdırmaz: yanlış ve süresi dolmuş kod aynı mesajı verir, kod
  isteği her e-posta için aynı yanıtı döner.
- Oturum gerektiren her istek `authorizedRequest` içinden geçer. Oturum yoksa `notAuthenticated`
  döner, "yetki yok" değil.

## Veri ve SQL

- Ev verisi taşıyan her tabloda `household_id` bulunur ve RLS açıktır. Politikalar
  `private.is_household_member(...)` kullanır ([ADR-0004](../decisions/0004-household-tenancy-and-row-level-security.md)).
- GRANT'lar açıktır (`auto_expose_new_tables = false`). Sunucunun atadığı kolonlar
  (`created_by`, `created_at`) istemciye GRANT edilmez.
- Çok adımlı yazma işlemleri `security definer` + `set search_path = ''` fonksiyonla tek
  transaction'da yapılır. Domain hata kodu özel SQLSTATE ile döner (`HM001` = zaten bir eve üye)
  ve `ErrorMapping`'de eşlenir.
- Kullanıcının oluşturduğu satırların kimliği cihazda üretilir (UUID). Ekleme
  `ON CONFLICT (id) DO NOTHING` ile idempotenttir.
- Liste sorguları `PageRequest` ile sayfalıdır (en fazla 50). Filtre ve sıralama kolonlarının
  indeksi overview'da yazılıdır.
- `CREATE INDEX` her zaman `CONCURRENTLY` ile ve tek ifadelik ayrı bir migration'da yazılır.
- Migration'lar geriye uyumludur: önce genişlet (expand), sonra taşı (migrate), sonra daralt (contract).

## Test yaklaşımı

- **Ne test edilir:**
  - Değer doğrulama ve Model davranışı unit test ile.
  - Adapter eşlemeleri unit test ile.
  - RLS ve tenant izolasyonu pgTAP ile.
  - Uçtan uca akış yerel Supabase'e karşı `SupabaseBackendIntegrationTests` ile.
- **Nerede:** `Packages/AppModules/Tests/<Modül>Tests/`, `AppTests/`, `supabase/tests/database/`.
- **Kurallar:**
  - Önce başarısız test yazılır (TDD).
  - Async testlerde `.timeLimit(.minutes(1))` kullanılır.
  - Fake'ler sistem sınırındadır (port protokolleri, saat). "Uçuşta" davranışı (çift gönderim)
    gate'li fake ile test edilir.
- **Zorunlu:** Her tablo için "başka evin verisini okuyamaz/yazamaz" ve "anon erişemez" testi.
  Her modül catalog'u için `LocalizationAudit` testi.
- Fixture'larda `try!` yok. Fixture fonksiyonları `throws` olur, testler `try` kullanır.

## Concurrency / state

- Feature modülleri ve App, varsayılan olarak `MainActor` izolasyonundadır. Core, adapter'lar ve
  test hedefleri `nonisolated` + `Sendable`'dır.
- Fake'ler `actor`'dür. Paylaşılan değişken durum `Mutex` (Synchronization) ya da `actor` içindedir.
- View'a bağlı async iş `.task` modifier'ıyla yapılır (iptali otomatiktir).
- Model'de çift gönderim koruması bir `isSubmitting`/`isAdding` bayrağıyla yapılır. View butonu
  bayrağa göre devre dışı bırakır.

## UI

- Sistem bileşenleri önce gelir: `NavigationStack`, `Form`, `List`, `ContentUnavailableView`.
  Liquid Glass yalnızca fonksiyonel katmanda kullanılır (bar, toolbar, yüzen aksiyonlar); satırlarda
  ve kartlarda kullanılmaz.
- Veri gösteren her ekranda loading, error (tekrar dene ile) ve empty durumları bulunur.
- Dynamic Type için sistem text style'ları kullanılır. Yalnızca ikon içeren butonlara
  `accessibilityLabel` verilir. Satırlar `.accessibilityElement(children: .combine)` ile okunur.
- Metin girişinin türü `textInput(.sentence | .email | .oneTimeCode)` ile verilir (klavye, otomatik
  doldurma ve büyük harf kuralı tek yerden).
- Vurgu rengi `AccentColor`'dır: açık modda `#17775F`, koyu modda `#2A9D7F`. Koyu zeminde metin
  için kontrast ≥ 4.5:1'dir.
- Arayüz metinleri modülün `Localizable.xcstrings` catalog'unda, anlamsal anahtarlarla
  (`shopping.empty.title`) tutulur. Her anahtarın tr ve en çevirisi bulunur.

## Loglama ve gizlilik

- `os.Logger(subsystem: "app.homeras", category: <modül>)` kullanılır, `print` kullanılmaz.
  Sunucu mesajları ve kullanıcı verisi `privacy: .private` ile loglanır.
- Token yalnızca Keychain'de saklanır. `UserDefaults`'a secret yazılmaz.
- Yeni bir kişisel veri alanı eklendiğinde overview'daki "Kişisel veri envanteri" ve
  `App/PrivacyInfo.xcprivacy` aynı değişiklikte güncellenir.

## Yasak desenler

| Yasak | Yerine | Neden |
|---|---|---|
| `!` (force unwrap), `try!`, `as!`, `var x: T!` | `guard let`, `try`, typed throws | Çökme yerine tipli hata |
| Gerekçesiz `@unchecked Sendable`, `nonisolated(unsafe)` | `actor`, `Mutex`, `@MainActor` | Strict concurrency |
| Boş `catch`, `try?` ile hata yutmak (değer kontrolü dışında) | `ErrorMapping` + Model'de `Failure` | Hata görünür kalır |
| View'da `SupabaseClient`/`URLSession` | Port protokolü + Model | Katman sınırı |
| Feature'dan feature'a veya adapter'a import | App'te composition | ADR-0001 |
| Kodda sabit metin (`Text("Ekle")`) | Catalog anahtarı + `bundle: .module` | i18n |
| Panelden elle şema değişikliği | Migration + pgTAP testi | ADR-0003 |
| RLS'siz tablo ya da `grant all` | Açık, kolon bazlı GRANT + politika | ADR-0004 |
| Service-role/secret anahtar istemcide ya da repoda | Yalnızca publishable key, `Config/Local.xcconfig` | ADR-0003 |
| `.xcodeproj`'u commit'lemek ya da elle düzenlemek | `project.yml` + `make generate` | ADR-0001 |
