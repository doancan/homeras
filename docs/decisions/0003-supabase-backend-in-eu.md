# 0003. Backend olarak AB bölgesinde Supabase kullan

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Ürün; kimlik doğrulama, ev bazında izole çok kiracılı veri, belge/fotoğraf depolama ve cihazlar
arası paylaşım istiyor (A-003, A-006). Android istemcisi gelecekte gelecek; CloudKit bunu dışlar.
Tek geliştirici ve ≤ 50 $/ay beta bütçesi var. Veri KVKK/GDPR kapsamında ve AB'de tutulmalı.

## Karar

- Supabase (Postgres 17 + PostgREST + GoTrue Auth + Storage), üretim projesi AB (Frankfurt) bölgesinde.
- Şema ve politikalar yalnızca `supabase/migrations/` altındaki SQL migration'larıyla değişir;
  panelden elle şema değişikliği yapılmaz. Yerel geliştirme `supabase start` (Docker) ile.
- İstemci SDK'sı `supabase-swift` (sürüm sabit) yalnızca `SupabaseBackend` modülünde kullanılır;
  diğer modüller Core portlarını görür. Backend değişirse yalnızca bu adapter değişir.
- İstemcide yalnızca publishable/anon anahtar bulunur; service-role anahtarı istemciye ve repoya girmez.
  URL ve anahtar `Config/*.xcconfig`'ten build ayarı olarak gelir, başlangıçta doğrulanır.
- Çok adımlı yazmalar (ör. ev + sahiplik) `security definer` Postgres fonksiyonlarıyla tek
  transaction'da yapılır; fonksiyonlar `search_path = ''` ile tanımlanır.
- Tablolar otomatik açılmaz (`auto_expose_new_tables = false`); her GRANT migration'da açıktır.

## Alternatifler

- **Özel API (Go/TypeScript) + yönetilen Postgres:** tam kontrol ama auth, depolama, dağıtım ve
  gözlemlenebilirliği yazmak MVP'yi haftalarca uzatır.
- **CloudKit + CKShare:** sunucu maliyeti yok ama Android yok, sunucu tarafı iş kuralı yazılamaz.
- **Firebase:** NoSQL veri modeli finans raporları ve ilişkisel tutarlılık için zayıf; AB veri
  yerleşimi ve kural dili daha kısıtlı.

## Sonuçlar

- **Olumlu:** tenant izolasyonu veritabanında zorlanır (ADR-0004), hızlı teslim, düz Postgres çıkış yolu.
- **Olumsuz / maliyet:** satıcı bağımlılığı; iş kuralının bir kısmı SQL'de yaşar ve pgTAP ile test edilmelidir.
- **Takip:** overview.md container diyagramı; conventions.md SQL kuralları; Q-006 (üretim hesabı).
