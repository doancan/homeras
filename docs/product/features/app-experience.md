# Özellik: Uygulama deneyimi (onaylı tasarım)

> Slug: `app-experience` · Q-007 kapandı · Durum: Onaylandı · Sahip: Doğancan · Son güncelleme: 2026-11-20
> Referans uygulama: git etiketi `ux-prototype-v1` (`prototype/` klasörü; SwiftUI, örnek veriyle)

## Problem

Ürünün bilgi mimarisi ve ekran akışları kod yazılmadan önce netleşmeliydi (Q-007). Tıklanabilir
prototip üç profilli bir incelemeden (ebeveyn, mali müşavir, fintech tasarımcısı) ve UXKIN'deki
gerçek uygulama referanslarından (Revolut, Klarna, Target, Orbit, Subo, Dime) geçti ve onaylandı.

## Kullanıcı

vision.md birincil ve ikincil personaları.

## Çözüm özeti

- **Sekmeler:** Bugün (dashboard) · Alışveriş · Ev (Stok / Eşyalar) · Bütçe · Ara (iOS arama
  sekmesi). Aile ve ayarlar Bugün'deki "Aile" düğmesinde.
- **Tek birincil aksiyon:** her sekmenin sağ üstünde vurgulu "+" (Hızlı ekle). İçeriği kapatan
  alt çubuk yok.
- **Bugün:** güvenle harcanabilir kartı (tempo grafiği, Yolunda/Plan üstünde, tutar gizleme),
  dört kısayol kutusu, azalanlar, yaklaşanlar (ödeme + hatırlatıcı + garanti), aile hareketleri;
  ilk açılışta "Evinizi kurun" kontrol listesi.
- **Alışveriş:** reyon sırasına göre gruplu liste, sık aldıklarınız, azalanlardan öneriler,
  "Bitir" ile stoğa ve gidere aktarma.
- **Ev:** konuma göre stok (sistem Stepper), odaya göre eşyalar, eşya detayında konum yolu,
  garanti ve belgeler.
- **Bütçe:** Özet / Hareketler / Planla — ayrıntı: [household-finance.md](household-finance.md).
- **Hızlı ekle:** Harcama (varsayılan, hatırlanır) / Alışveriş / Stok; büyük tutar, kategori
  çipleri, son harcamalar, ödeyen, görünürlük, tarih, taksit, banka SMS'i; ekle düğmesi altta;
  kayıt sonrası "Geri al" bildirimi.
- **Görsel dil:** iOS 27 HIG, sistem bileşenleri önce; Liquid Glass yalnızca fonksiyonel katmanda;
  vurgu `#254940` / koyu `#4FA58C`, uyarı `#B8662E` / `#EBA36D`; kategori başına renk; tek
  ilerleme dili (BudgetMeter, tempo çizgili); SF Symbols (marka logosu yok).
- **Erişilebilirlik:** en büyük yazı boyutunda satırlar dikey dizilir, tutarlar bölünmez; durum
  hiçbir yerde yalnızca renkle verilmez; isimlerden sonra Türkçe ek üretilmez.

## Kabul kriterleri

| # | Given / When / Then | Test |
|---|---------------------|------|
| AC-1 | **Given** herhangi bir sekme **When** açılır **Then** sağ üstte tek vurgulu "+" bulunur ve içerik üstüne binen kalıcı çubuk yoktur | UI testi |
| AC-2 | **Given** en büyük yazı boyutu **When** Bugün, Ev, Bütçe, Alışveriş açılır **Then** kelime ortadan bölünmez, tutar kesilmez | Görsel kontrol (iOS 26 ve 27) |
| AC-3 | **Given** "Tutarları gizle" açık **When** finans içeren her ekran açılır **Then** hiçbir tutar okunmaz | UI testi |
| AC-4 | **Given** harcama eklendi **When** 5 saniye içinde "Geri al"a basılır **Then** kayıt ve bütçe etkisi geri alınır | Model testi |

## Kapsam dışı

- Prototipteki örnek veri ve demo başlatma parametreleri ürüne taşınmaz.
- Dashboard kartlarını kullanıcının yeniden sıralaması (FR-077, Sonraki).

## Açık sorular

- Q-001: nihai marka adı ve bundle id (uygulama simgesi ve App Store kimliği buna bağlı).
