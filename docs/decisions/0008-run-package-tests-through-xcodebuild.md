# 0008. Paket testlerini `swift test` yerine `xcodebuild` ile çalıştır

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

ADR-0001 ve ADR-0002 paket testlerini simülatörsüz `swift test` ile çalıştırmayı öngörüyordu.
CI ilk kez Xcode 26.6 ile koştuğunda yerelleştirme testleri düştü: Xcode 26'nın komut satırı
SwiftPM'i String Catalog'ları (`.xcstrings`) modül bundle'ına derlemiyor. Bu yüzden metinler ham
anahtar olarak kalıyor. Xcode 27.2'de aynı komut çalışıyor. Uygulama ise her zaman `xcodebuild`
ile derlendiği için catalog'lar orada sorunsuz.

## Karar

`make test-packages`, paket testlerini `xcodebuild test -scheme AppModules-Package -destination
'platform=macOS'` ile çalıştırır. Bu, uygulamanın derlendiği yolun aynısıdır ve her Xcode
sürümünde aynı davranır. Entegrasyon testleri (`make verify-integration`) catalog kullanmadığı
için ortam değişkeni geçirmesi kolay olan `swift test` ile kalır. ADR-0001'deki "macOS desteği
yalnızca hızlı paket testleri içindir" gerekçesi geçerlidir.

## Alternatifler

- **`swift test` ile devam edip catalog'ları elle `.strings`'e çevirmek:** String Catalog'un
  çeviri durumu takibini kaybettirir, üretilmiş dosya bakımı getirir.
- **Yerelleştirme testlerini yalnızca app testlerine taşımak:** Modül bazında eksik çeviri
  kontrolünü kaybettirir.

## Sonuçlar

- **Olumlu:** Testler uygulamayla aynı derleme yolunda; Xcode 26 ve 27'de aynı sonuç.
- **Olumsuz / maliyet:** `xcodebuild` `swift test`'ten birkaç saniye yavaş.
- **Takip:** Makefile `test-packages` hedefi.
