# Homeras

Ailelerin evin finansını, stoklarını, eşyalarını, ortak alışverişini ve hatırlatıcılarını tek bir
iPhone uygulamasında yönettiği platform. Native iOS 26+ (Swift 6, SwiftUI) istemcisi ve AB'de
barındırılan Supabase backend'inden oluşur. Ev (household) tenant'tır; veri ev bazında Postgres
RLS ile izole edilir. Çalışma adıdır, marka kararı açık (Q-001).

## Mevcut durum

- **Aşama:** walking skeleton (MVP öncesi).
- **Çalışan:**
  - E-posta koduyla giriş (FR-001).
  - Ev oluşturma (FR-003).
  - Ortak alışveriş listesine ekleme ve sayfalı listeleme (FR-040). Ekleme idempotent; başka
    evin üyesi listeyi göremez ve yazamaz.
  - Çıkış.
- **Testler:**
  - 78 paket unit testi + 14 app testi.
  - 22 pgTAP RLS/tenant testi.
  - Yerel Supabase'e karşı 6 uçtan uca test.
- **UX onaylandı:** [features/app-experience.md](product/features/app-experience.md); referans prototip `ux-prototype-v1` etiketinde. Mevcut ürün ekranları bu tasarıma taşınacak.
- **Uygulama ikonu:** `design/logo-v1.svg` kaynağından üretilen geçici ikon (v1). Marka kararı
  Q-001'de açık.
- **Eksik:**
  - Sign in with Apple (FR-002, Team ID bekliyor: Q-005).
  - Offline yazma (FR-044).
- **Bilinen sorunlar ve borçlar:** [tech-debt.md](architecture/tech-debt.md) (TD-001, TD-002).

## Geçerli kısıtlar

- Projede yalnızca iOS 26+ ve Swift 6 strict concurrency kullanılır; Xcode projesi `project.yml`'den üretilir, commit'lenmez — [ADR-0001](decisions/0001-native-ios-with-modular-spm-structure.md)
- Feature modülleri birbirini ve adapter'ları import edemez — [ADR-0001](decisions/0001-native-ios-with-modular-spm-structure.md)
- Bir değişiklik `make verify` yeşil olmadan bitmiş sayılmaz; şema değişikliği `make verify-db` ister — [ADR-0002](decisions/0002-single-verify-entry-point-and-ci.md)
- Şema yalnızca `supabase/migrations/` ile değişir; istemcide yalnızca publishable key bulunur — [ADR-0003](decisions/0003-supabase-backend-in-eu.md)
- Ev verisi taşıyan her tabloda RLS ve pgTAP izolasyon testi zorunludur — [ADR-0004](decisions/0004-household-tenancy-and-row-level-security.md)
- Finans: gider bir kez tanınır, ekstre ödemesi transferdir; tutarlar kuruş tam sayı — [ADR-0009](decisions/0009-household-finance-ledger-model.md)
- Stok miktarı mutlak değer değil, hareket (delta) olarak yazılır — [ADR-0005](decisions/0005-offline-first-sync-with-outbox.md)
- Parola yok; auth hataları hesap varlığını sızdırmaz; token yalnızca Keychain'de saklanır — [ADR-0006](decisions/0006-auth-email-otp-and-sign-in-with-apple.md)
- En güncel SDK ve iOS 27 HIG; minimum iOS 26.0, iOS 27 API'leri `#available` ile ve iOS 26 karşılığıyla; ekranlar iki sürümde de görülür — [ADR-0007](decisions/0007-ios-27-sdk-and-hig-with-ios-26-floor.md)

## Sonraki adımlar

0. **Doğrulanmadı:** iOS 26 görünümü (ADR-0007). Ekranlar yalnızca iOS 27.2 simülatöründe
   görüldü, çünkü bu makinede iOS 26 runtime'ı kurulu değil. Kurulum:
   `xcodebuild -downloadPlatform iOS -buildVersion 26.3`.
1. Onaylı tasarımı ürüne taşımak (app-experience.md): sekme yapısı, Hızlı ekle, Bugün dashboard'u; ardından finans dilimi (household-finance.md, ADR-0009).
2. FR-004/FR-005: aile daveti (hash'li, tek kullanımlık, 72 saat geçerli kod), ardından
   FR-041 (alındı işaretleme).
3. FR-002: Sign in with Apple (Q-005 Team ID gelince), TD-002, ilk TestFlight.

## Hızlı başlangıç

**Gereksinimler:**
- Xcode 27.2 (iOS 27.2 SDK; deployment target iOS 26.0).
- `brew install xcodegen supabase/tap/supabase` (gitleaks isteğe bağlı; yoksa `make verify-security` sabitlenmiş Docker imajını kullanır).
- Docker (yerel Supabase için).

```sh
make setup          # araçları kontrol et, Swift paketlerini çöz (ağ gerekir)
make db-start       # yerel Supabase'i başlat (Docker; API 127.0.0.1:54721, Mailpit 54724)
make local-config   # Config/Local.xcconfig'i yerel yığına göre yaz
make run            # uygulamayı simülatörde derle ve aç
make help           # tüm hedefler
```

**Giriş kodu (yerel):** E-postalar gerçekten gönderilmez; kodu http://127.0.0.1:54724 adresindeki
Mailpit'ten okuyun.

**Ortam ayarları:** Backend URL'i ve publishable key, `Config/Local.xcconfig` dosyasından gelir
(git'e girmez; örnek: `Config/Local.xcconfig.example`). Takım ve bundle id de burada ayarlanır.

## Doğrulama

```sh
make verify   # format kontrolü → strict derleme + paket testleri → iOS simülatöründe app testleri
```

Bir değişiklik bu komut yeşil olmadan bitmiş sayılmaz. Ek kapılar:
- `make verify-db`: migration'ları sıfırdan uygular ve pgTAP RLS testlerini çalıştırır.
- `make verify-integration`: `verify-db` + uçtan uca Swift testleri.
- `make verify-security`: secret taraması.

CI (`.github/workflows/ci.yml`) `verify`, `verify-db` ve `verify-security` kapılarını çalıştırır.

## Proje yapısı

```
App/, AppTests/        # ince iOS app: composition root, kök akış, yapılandırma, app testleri
Packages/AppModules/   # SPM modülleri: Core, DesignSystem, SupabaseBackend, *Feature, TestSupport
supabase/              # config, migration'lar, pgTAP testleri, e-posta şablonu
Config/                # xcconfig (Local.xcconfig git dışı)
design/                # tasarım kaynakları (logo/ikon SVG)
project.yml, Makefile  # Xcode projesi kaynağı; tek doğrulama giriş noktası
```

## Docs haritası

| Doküman | Ne zaman oku |
|---|---|
| [product/vision.md](product/vision.md) | Ürünün neden var olduğu, kim için olduğu, başarı metrikleri |
| [product/requirements.md](product/requirements.md) | Davranış değişikliğinden önce (FR, NFR, varsayımlar, açık sorular) |
| [architecture/overview.md](architecture/overview.md) | Modül ekleme/taşıma, veri akışı veya şema değişikliği |
| [architecture/conventions.md](architecture/conventions.md) | Her kod değişikliğinden önce |
| [architecture/tech-debt.md](architecture/tech-debt.md) | Borç eklerken ya da öderken |
| [decisions/](decisions/) | Bir yaklaşımın "neden"i sorulduğunda; mimari değişiklikten önce |

## Son kararlar

- [0009 — Ev finansı defter modeli](decisions/0009-household-finance-ledger-model.md)
- [0008 — Paket testleri `xcodebuild` ile](decisions/0008-run-package-tests-through-xcodebuild.md)
- [0007 — iOS 27 SDK ve HIG, iOS 26 tabanı](decisions/0007-ios-27-sdk-and-hig-with-ios-26-floor.md)
- [0006 — E-posta OTP + Sign in with Apple](decisions/0006-auth-email-otp-and-sign-in-with-apple.md)
- [0005 — Offline-first: GRDB + outbox, stokta delta](decisions/0005-offline-first-sync-with-outbox.md)

## Çalışma kuralı

Her değişiklikte sırasıyla:
1. İlgili dokümanı oku.
2. Uygula.
3. Docs'u aynı değişiklikte güncelle.
4. Karar alındıysa ADR yaz.
5. `make verify` çalıştır.
