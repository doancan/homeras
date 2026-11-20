# 0007. iOS 27 SDK ve HIG'i hedefle, iOS 26'yı taban olarak koru

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Ürün sahibi arayüzün Apple'ın en güncel kurallarına (iOS 27 Human Interface Guidelines) göre
yapılmasını, aynı zamanda geriye dönük uyumluluğun korunmasını istiyor. Nisan 2027'den itibaren
App Store'a yüklenen iPhone uygulamaları iOS 27 SDK ile derlenmek zorunda; iPhone Duo (iOS 27.1)
için ekran görüntüsü de zorunlu oluyor. iOS 27, iOS 26 ile aynı cihazları (iPhone 11 ve sonrası)
destekliyor. ADR-0001 minimum sürümü iOS 26.0 olarak belirledi.

## Karar

- Uygulama her zaman en güncel Xcode ve iOS SDK'sıyla derlenir (bugün Xcode 27.2 / iOS 27.2 SDK).
- Tasarım ve davranış iOS 27 HIG'e göre yapılır (Liquid Glass, iPhone Duo, 2026 Branding ve
  Sheets kuralları dahil).
- Minimum sürüm iOS 26.0 kalır. iOS 27'ye özgü her API `if #available(iOS 27.0, *)` ile kullanılır
  ve iOS 26'da çalışan bir karşılığı bulunur. Karşılığı olmayan iOS 27 API'si yalnızca
  davranışı zenginleştirir; hiçbir akış ona bağımlı olmaz.
- Kullanımdan kalkan (deprecated) API yeni kodda kullanılmaz; 27 SDK'da kaldırılanların yerine
  geçenler kullanılır.
- Her ekran hem iOS 26 hem iOS 27 simülatöründe, açık/koyu modda ve en büyük yazı boyutunda
  görülerek kabul edilir.
- iPhone Duo uyumu: sistem bar'ları varsayılan yerinde kalır, her toolbar öğesinin başlığı ve
  sembolü bulunur, yüzen özel kontroller yan bar bölgesinden uzak tutulur.

## Alternatifler

- **Minimum iOS 27.0:** API'ler sadeleşir ama iOS 26'da kalan kullanıcılar dışarıda kalır; aynı
  cihazlar desteklendiği için bu kısıtın ürün açısından karşılığı yok.
- **iOS 27 API'lerini hiç kullanmamak (yalnızca iOS 26 seviyesi):** uyumluluk kolaylaşır ama
  güncel HIG davranışları (sekme rolleri, toolbar küçülmesi, erişilebilir sekme seçiciler) kaçar.

## Sonuçlar

- **Olumlu:** güncel tasarım dili ve App Store gereksinimleriyle uyum, iOS 26 kullanıcıları korunur.
- **Olumsuz / maliyet:** her iOS 27 API'si için iki yol yazılır ve iki sürümde test edilir.
- **Takip:** conventions.md UI bölümü; README "Geçerli kısıtlar"; CI Xcode sürümü güncel tutulur.
