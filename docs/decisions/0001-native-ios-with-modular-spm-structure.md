# 0001. iOS istemcisini Swift 6 + SwiftUI ile, XcodeGen ve yerel SPM modülleriyle kur

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Homeras yalnızca iPhone hedefli (iOS 26+, A-002), tek geliştiricinin yıllarca bakımını yapacağı bir
uygulama. Modüller (finans, stok, envanter, alışveriş, hatırlatıcı) birbirine bağlı ama bağımsız
test edilebilmeli. Proje dosyası merge çatışması üretmemeli ve CI'da GUI adımı olmadan üretilebilmeli.

## Karar

- Dil Swift 6 (tam strict concurrency), UI SwiftUI + Observation (`@Observable`), test Swift Testing.
- Minimum sürüm iOS 26.0. Paket ayrıca macOS 26'yı destekler; tek amacı paket testlerinin
  simülatörsüz `swift test` ile hızlı koşmasıdır. Feature kodu iOS'a özgü API'yi `#if os(iOS)` ile sarar.
- Xcode projesi `project.yml`'den XcodeGen ile üretilir; `*.xcodeproj` commit'lenmez.
- Kod yerel bir SPM paketinde (`Packages/AppModules`) modüllere bölünür:
  - `Core`: domain tipleri, değer doğrulama, port protokolleri, hata tipleri. UI ve ağ import etmez.
  - Adapter'lar (ör. `SupabaseBackend`): Core portlarını uygular.
  - `<Ad>Feature`: SwiftUI View + `@Observable` Model; yalnızca `Core`'a bağımlıdır.
  - `App` hedefi incedir: composition root (`AppEnvironment`) ve kök akış.
- Modül sınırları derleyiciyle zorlanır: feature'lar birbirini ve adapter'ları import edemez
  (Package.swift bağımlılıkları).

## Alternatifler

- **Tek Xcode target, klasörlerle ayrım:** sınır derleyiciyle zorlanmaz, testler app'i host etmek zorunda kalır.
- **Tuist:** daha güçlü ama ek araç ve öğrenme maliyeti; mevcut ihtiyaç XcodeGen ile karşılanıyor.
- **TCA (The Composable Architecture):** güçlü test edilebilirlik ama ağır bağımlılık ve öğrenme
  eğrisi; `@Observable` Model + protokol DI aynı test edilebilirliği bağımlılıksız sağlıyor.
- **SwiftUI yerine UIKit:** iOS 26 için SwiftUI olgun; UIKit yalnızca eksik kalan yerde sarmalanır.

## Sonuçlar

- **Olumlu:** modül başına hızlı test, derleyiciyle zorlanan bağımlılık yönü, çatışmasız proje dosyası.
- **Olumsuz / maliyet:** XcodeGen kurulumu gerekir; `make generate` her build öncesi çalışır.
- **Takip:** overview.md modül tablosu, conventions.md katman kuralları.
