# 0004. Ev (household) tenant'tır; yetki Postgres RLS ile zorlanır

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Her ailenin verisi diğer ailelerden kesin olarak izole olmalı (NFR-SEC). Ev içinde roller var
(A-004) ve kişisel finans kayıtları yalnızca sahibine görünmeli (A-005). İstemci güvenilmezdir:
tenant kimliği istemciden gelen bir parametreye dayanamaz.

## Karar

- Ev verisi taşıyan her tabloda `household_id` bulunur ve RLS açıktır. Politikalar üyeliği
  `private.is_household_member(household_id)` ile `auth.uid()` üzerinden kontrol eder.
- Roller: `owner`, `admin`, `member` (`household_role` enum'u). Rol gerektiren işlemler kendi
  politikası ya da `security definer` fonksiyonuyla kontrol edilir.
- Kişisel kayıtlar (finans dilimi): `visibility = 'personal'` satırları yalnızca `owner_id = auth.uid()`
  için görünür. Üye ayrılınca kişisel kayıtları silinir, ortak kayıtlarda yazar `null` olur ("eski üye").
- Sunucu atadığı alanlar (`created_by`, `created_at`) istemciye kolon bazlı GRANT ile açılmaz.
- MVP'de bir kullanıcı en fazla bir eve üyedir (`create_household` HM001); şema çoklu eve hazırdır.
- Her tablo için pgTAP testi zorunludur: başka evin verisini okuyamaz/yazamaz, anon erişemez.
- Davet tokenları (FR-004) yalnızca hash'li saklanır, tek kullanımlık ve 72 saat geçerlidir.

## Alternatifler

- **Uygulama katmanında filtre (her sorguda `where household_id`):** unutulan tek filtre veri sızdırır.
- **Ev başına ayrı şema/veritabanı:** 1.000 ev için operasyonel yük orantısız.

## Sonuçlar

- **Olumlu:** izolasyon istemci hatasına dayanıklı; Android istemcisi aynı garantiyi bedavaya alır.
- **Olumsuz / maliyet:** politika hataları sessiz boş sonuç döndürür; bu yüzden pgTAP testleri zorunlu.
- **Takip:** `supabase/tests/database/`; conventions.md SQL kuralları.
