# 0002. Kalite kapılarını `make verify` ve GitHub Actions ile zorla

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Kalite kuralları (format, strict derleme, testler, RLS testleri) belgede kalırsa zamanla aşınır.
Yerel geliştirme ile CI'ın aynı kapıları aynı komutla çalıştırması gerekir.

## Karar

- `make verify`: format-check (toolchain'deki `swift format`, `.swift-format`) → paket testleri
  (`swift test`, uyarı = hata) → iOS simülatöründe app derleme + app testleri. Ağ gerektirmez.
- `make verify-db`: yerel Supabase (Docker) üzerinde migration'ları sıfırdan uygular ve pgTAP
  RLS/tenant testlerini çalıştırır (`supabase test db`).
- `make verify-integration`: `verify-db` + Swift adapter'ının yerel Supabase'e karşı uçtan uca testi.
- `make verify-security`: `gitleaks` ile secret taraması. SPM için standart zafiyet tarayıcısı
  olmadığından bağımlılıklar sürüm sabitli (`exact:`), `Package.resolved` commit'lenir, her yeni
  bağımlılık ADR ister.
- CI (GitHub Actions): `ios` işi `make setup verify`; `db` işi Ubuntu'da `make verify-db`;
  `security` işi `make verify-security`. Her iş zaman sınırlıdır.
- Lint için ayrı SwiftLint yok; `swift format lint --strict` + derleyici uyarıları hata.

## Alternatifler

- **Fastlane:** imza/dağıtım için değerli ama doğrulama için gereksiz katman; dağıtım dilimi geldiğinde ayrıca değerlendirilir.
- **SwiftLint:** ek kural gücü sağlar ama ek bağımlılık; özel kural ihtiyacı doğarsa ADR ile eklenir.
- **Xcode Cloud:** Apple Developer hesabı gerektirir (Q-005) ve DB testlerini çalıştıramaz.

## Sonuçlar

- **Olumlu:** tek komut, CI ile birebir aynı; tenant izolasyonu her PR'da test edilir.
- **Olumsuz / maliyet:** `verify-db` Docker ister; Swift entegrasyon testleri yalnızca yerelde
  (macOS CI runner'larında Docker yok).
- **Takip:** README "Doğrulama", conventions.md "Araçlar".
