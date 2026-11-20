# Özellik: Ev finansı

> Slug: `household-finance` · FR: FR-010…FR-019, FR-071, FR-073…FR-079 · Durum: Onaylandı ·
> Sahip: Doğancan · Son güncelleme: 2026-11-20 · Model: [ADR-0009](../../decisions/0009-household-finance-ledger-model.md)

## Problem

Aileler bütçeyi Excel, not uygulaması ve WhatsApp arasında tutuyor. İki maaş, kartla taksitli
alışveriş ve "ortak gideri kim ödedi" sorusu yüzünden ay sonunda kimse gerçek durumu bilmiyor.
Mevcut uygulamalar ya tek kişilik ya da banka bağlantısı istiyor.

## Kullanıcı

Ortak evi yöneten yetişkinler (vision.md birincil persona) ve eşleri.

## Çözüm özeti

- **Güvenle harcanabilir:** bir sonraki maaşa kadar günde ne harcanabileceği; yaklaşan ekstre,
  fatura, taksit ve birikim taahhüdü düşülmüş, hesabı ⓘ ile açık.
- **Gelir ve maaş günleri:** üye başına maaş/gelir; dönem maaş döngüsüne göre.
- **Kim ödedi, bölüşüm, hesaplaşma:** ortak gider %50/50 ya da gelire orantılı; ay sonu özeti.
- **Görünürlük:** Ortak / Eşimle / Kişisel.
- **Hızlı giriş:** büyük tutar, kategori çipleri, son işyerleri, ödeyen, tarih; banka SMS'i cihazda
  okunur; Siri/Kısayollar, Kontrol Merkezi, widget, Paylaş uzantısı (Sonraki).
- **Bütçe sekmesi:** Özet / Hareketler / Planla; Planla'da yöntem, maaş günleri, kategoriler ve
  limitler, hızlı tutarlar, bildirimler.
- **Ödemeler:** kart ekstreleri (kesim döngüsüne duyarlı), taksitler, düzenli ödemeler.
- **Eşe anlık bildirim:** "Can ₺120 Market ekledi"; her üye kendi bildirimlerini seçer.

## Kabul kriterleri

| # | Given / When / Then | Test |
|---|---------------------|------|
| AC-1 | **Given** maaşlar ayın 1'i ve 15'i, bugün 20'si **When** Özet açılır **Then** "maaşa kalan gün" 1'ine göre hesaplanır | |
| AC-2 | **Given** maaşa kadar ₺8.454 ekstre son ödemesi var **When** güvenle harcanabilir hesaplanır **Then** ekstre düşülür ve ⓘ kırılımında görünür | |
| AC-3 | **Given** kartla ₺1.000 harcama gider yazıldı **When** ekstre ödendi işaretlenir **Then** yeni gider oluşmaz, transfer oluşur | |
| AC-4 | **Given** ₺1.000 3 taksit **When** plan oluşturulur **Then** taksitler 333,34 + 333,33 + 333,33 olur | |
| AC-5 | **Given** Can ortak ₺600 ödedi, bölüşüm %50 **When** hesaplaşma açılır **Then** "Elif, Can'a ₺300 borçlu" görünür | |
| AC-6 | (yetki) **Given** Elif'in kişisel kaydı **When** Can raporları açar **Then** kayıt ne listede ne toplamda görünür | |
| AC-7 | **Given** geçen ayın ilk 20 günü ₺15.000 **When** bu ayın 20. günü ₺18.420 harcanmışsa **Then** kıyas +%23 der (tam ay değil, aynı dönem) | |
| AC-8 | (hata) **Given** OTP ya da reklam SMS'i **When** yapıştırılır **Then** harcama oluşmaz, kullanıcıya açık uyarı gösterilir | |
| AC-9 | **Given** "Tutarları gizle" açık **When** herhangi bir finans ekranı açılır **Then** hiçbir tutar okunmaz (VoiceOver "gizli" der) | |
| AC-10 | **Given** Can harcama ekler ve Elif bildirimi açıktır **When** kayıt sunucuya ulaşır **Then** Elif'e bildirim gider; Can'a gitmez | |

## Sınır durumları

- Maaş günü 29–31: kısa aylarda ayın son günü; hafta sonu/tatil: bir önceki iş günü.
- Limit ya da geçen ay toplamı 0: oran gösterilmez, sıfıra bölme yok.
- Dövizli harcama: tutar kendi birimiyle, TL karşılığı "tahmini" olarak tutulur (Sonraki).
- Eşzamanlı düzenleme: işlemler değişmez olay; düzeltme yeni olaydır (ADR-0005, ADR-0009).
- Başka ev: tüm finans tabloları RLS ile izole (ADR-0004).

## Hata durumları

| Hata | Kullanıcı ne görür | Sistem ne yapar |
|------|--------------------|-----------------|
| SMS'te tutar yok / OTP | "Bu metinde harcama tutarı bulunamadı" | Kayıt oluşturmaz |
| Çevrimdışı ekleme | Kayıt "bekliyor" rozetiyle listede | Outbox, ağ gelince gönderir |
| Bildirim izni yok | Planla › Bildirimler'de izin açıklaması ve Ayarlar bağlantısı | Uygulama içi rozet |

## NFR etkisi

- NFR-PRIV: SMS metni cihazda işlenir, sunucuya gitmez; `private` satırlar toplamlara girmez.
- NFR-OFF: finans yazmaları outbox üzerinden, idempotent.

## Metrik

Beta hanelerinin %50'si ilk 4 haftada en az bir hesaplaşma yapar; giriş başına ortanca süre < 8 sn.

## Etkilenen dokümanlar

- [x] `docs/product/requirements.md`
- [x] `docs/decisions/0009-household-finance-ledger-model.md`
- [ ] `docs/architecture/overview.md` (tablolar ürün dilimine girince)

## Kapsam dışı

- Banka hesabı bağlantısı ve otomatik içe aktarma (vision non-goal).
- Yatırım portföyü (hisse) takibi.

## Açık sorular

- Q-008: FinanceKit / Apple Wallet işlem erişimi Türk banka kartları için mümkün mü? (doğrulanmadan plana girmez)
