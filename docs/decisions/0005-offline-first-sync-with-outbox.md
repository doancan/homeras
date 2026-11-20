# 0005. Offline-first: yerel SQLite (GRDB) + outbox; metinde LWW, stokta delta

- **Durum:** Kabul (uygulama FR-044 diliminde)
- **Tarih:** 2026-11-20

## Bağlam

Alışveriş listesi markette zayıf sinyalde kullanılır (FR-044, A-007). Birden çok üye aynı veriyi
aynı anda değiştirir; stok miktarında kayıp kabul edilemez (FR-021).

## Karar

- Her feature verisi cihazda SQLite'ta (GRDB) tutulur; ekranlar yerel veriden okur.
- Yazmalar önce yerele, aynı transaction'da outbox tablosuna yazılır. Senkronizasyon motoru
  outbox'ı sırayla, istemci üretimli UUID ile idempotent gönderir; başarıda kaydı siler.
- Çakışma: metin/alan güncellemelerinde sunucu `updated_at`'ine göre son yazan kazanır.
  Stok miktarı satır olarak değil `stock_movements(delta)` hareketleri olarak gönderilir;
  miktar hareketlerin toplamıdır, böylece eşzamanlı +/- işlemleri kaybolmaz.
- Çekme: `updated_at` imleciyle artımlı; silmeler tombstone (`deleted_at`) ile taşınır.
- Walking skeleton bu katman olmadan doğrudan backend'den okur; port arayüzleri (Core) bu
  yüzden konumdan bağımsız tasarlanır ve FR-044'te yalnızca adapter değişir.

## Alternatifler

- **SwiftData:** birinci taraf ama outbox/transaction kontrolü ve migration davranışı kısıtlı,
  Swift 6 concurrency ile sürtünmeli.
- **Core Data + NSPersistentCloudKitContainer:** CloudKit'e bağlar (ADR-0003 ile çelişir).
- **PowerSync / ElectricSQL gibi hazır sync:** ek ücretli servis ve bağımlılık; beta ölçeğinde gereksiz.

## Sonuçlar

- **Olumlu:** anında açılan ekranlar, offline yazma, stokta kayıpsız birleşme, tüketim geçmişi.
- **Olumsuz / maliyet:** sync motoru bizim sorumluluğumuzda; ayrı test seti gerekir.
- **Takip:** FR-044 dilimi başlarken GRDB bağımlılığı eklenir ve `features/offline-sync.md` yazılır.
