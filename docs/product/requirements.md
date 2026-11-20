# Gereksinimler: Homeras

> Son güncelleme: 2026-11-20 · Vizyon: [vision.md](vision.md)

MVP 7 alanı kapsar (hesap/ev, finans, stok, envanter, alışveriş, hatırlatıcı, ana sayfa).
FR sayısı 7'yi aştığı için MVP, README "Sonraki adımlar"daki dikey dilimlerle teslim edilir.
Alan bazında S2 seviyesindeki işler başlamadan önce `features/<slug>.md` spec'i yazılır.

## Fonksiyonel gereksinimler

Öncelik: MVP / Sonraki / Belki · Durum: Taslak / Onaylandı / Geliştiriliyor / Tamamlandı / İptal

### Hesap, ev ve üyelik

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-001 | E-posta ile tek kullanımlık kodla giriş | **Given** geçerli e-posta **When** kod istenir ve doğru kod girilir **Then** oturum açılır; yanlış/süresi dolmuş kodda genel hata gösterilir, hesabın varlığı sızdırılmaz | MVP | Geliştiriliyor | — |
| FR-002 | Sign in with Apple ile giriş | **Given** Apple kimliği **When** kullanıcı onaylar **Then** oturum açılır; e-posta gizleme (relay) desteklenir | MVP | Onaylandı | — |
| FR-003 | Ev oluşturma | **Given** evi olmayan oturumlu kullanıcı **When** 1–60 karakter ad girer **Then** ev oluşur ve kullanıcı Sahip olur; boş ad reddedilir | MVP | Geliştiriliyor | — |
| FR-004 | Üye davet etme | **Given** Sahip/Yönetici **When** davet oluşturur **Then** tek kullanımlık, 72 saat geçerli kod/link üretilir; Üye rolü davet oluşturamaz | MVP | Onaylandı | — |
| FR-005 | Daveti kabul etme | **Given** geçerli davet **When** oturumlu kullanıcı kabul eder **Then** eve Üye olarak eklenir; kullanılmış/süresi dolmuş/bilinmeyen kod aynı genel hatayı verir | MVP | Onaylandı | — |
| FR-006 | Rol yönetimi ve evden çıkarma/ayrılma | **Given** Sahip **When** üyenin rolünü değiştirir veya çıkarır **Then** yetkileri hemen düşer; ayrılan üyenin kişisel kayıtları kendisiyle gider, ortak kayıtlar evde kalır ve "eski üye" olarak gösterilir; son Sahip evi terk edemez | MVP | Onaylandı | — |
| FR-007 | Uygulama içinden hesap silme | **Given** oturumlu kullanıcı **When** silmeyi onaylar **Then** hesap ve kişisel verisi ≤ 30 gün içinde kalıcı silinir, oturumlar iptal edilir; tek Sahip olduğu ev varsa önce devir veya ev silme istenir | MVP | Onaylandı | — |
| FR-008 | Birden fazla ev yönetimi | Arayüz ve ev değiştirici | Sonraki | Taslak | — |
| FR-009 | Çocuk hesapları ve kısıtlı roller | — | Sonraki | Taslak | — |

### Finans ve bütçe

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-010 | Gelir/gider kaydı (tutar, tarih, kategori, not, kişisel/ortak) | **Given** üye **When** tutar > 0 ve kategori ile kaydeder **Then** kayıt listede görünür; kişisel kaydı yalnızca sahibi görür (başka üye API'den de okuyamaz) | MVP | Onaylandı | — |
| FR-011 | Harcama kategorileri (varsayılan set + özel) | **Given** ev **When** oluşturulur **Then** varsayılan kategoriler gelir; üye yeni kategori ekleyebilir, kullanılan kategori silinmez arşivlenir | MVP | Onaylandı | — |
| FR-012 | Aylık ortak bütçe ve kategori limiti | **Given** limit tanımlı **When** ortak harcamalar limitin %80'ine/%100'üne ulaşır **Then** ana sayfada uyarı ve bildirim | MVP | Onaylandı | — |
| FR-013 | Düzenli ödemeler (fatura, abonelik) | **Given** tekrar kuralı (aylık/yıllık) **When** vade yaklaşır **Then** FR-050 ile hatırlatılır; ödendi işaretlenince gider kaydı oluşur | MVP | Onaylandı | — |
| FR-014 | Aylık ve yıllık rapor | **Given** dönem **When** açılır **Then** kategori bazlı toplamlar; kişisel kayıtlar yalnızca sahibinin raporunda | MVP | Onaylandı | — |
| FR-015 | Ay sonu bütçe tahmini ve tasarruf önerileri | — | Sonraki | Taslak | — |

### Ev stok yönetimi

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-020 | Stok ürünü (ad, birim, saklama yeri, minimum seviye) | **Given** üye **When** ürün ekler **Then** miktar 0 ile başlar; aynı evde aynı ad+birim tekrarlanamaz | MVP | Onaylandı | — |
| FR-021 | Stok artırma/azaltma | **Given** ürün **When** +/- işlemi yapılır **Then** işlem hareket (delta) olarak kaydedilir; iki cihazdan eşzamanlı azaltma ikisini de korur; miktar 0'ın altına inmez | MVP | Onaylandı | — |
| FR-022 | Minimum seviyede alışveriş önerisi | **Given** miktar ≤ minimum **When** hareket kaydedilir **Then** ürün alışveriş listesine öneri olarak düşer (otomatik eklenmez) | MVP | Onaylandı | — |
| FR-023 | Stok listesi ve arama | **Given** ≥ 1 ürün **When** ad/yer ile aranır **Then** sonuç sayfalı (50) döner; boş durum gösterilir | MVP | Onaylandı | — |
| FR-024 | Tüketim tahmini (bitiş tarihi) | — | Sonraki | Taslak | — |
| FR-025 | NFC/QR/fiziksel buton ile stok azaltma | — | Sonraki | Taslak | — |

### Ev envanteri ve demirbaşlar

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-030 | Eşya kaydı (ad, fotoğraf, konum: oda/dolap/çekmece/kutu) | **Given** üye **When** eşya ekler **Then** kayıt ve konum görünür; fotoğraf özel depoda, ≤ 10 MB, EXIF konum verisi silinir | MVP | Onaylandı | — |
| FR-031 | Satın alma bilgisi (tarih, fiyat, mağaza) ve garanti bitişi | **Given** garanti tarihi **When** 30 gün kalır **Then** FR-050 hatırlatıcısı | MVP | Onaylandı | — |
| FR-032 | Fatura/garanti belgesi ekleme (PDF/görsel) | **Given** eşya **When** belge eklenir **Then** yalnızca ev üyeleri kısa ömürlü imzalı URL ile açabilir | MVP | Onaylandı | — |
| FR-033 | Eşya arama ("HDMI kablo nerede?") | **Given** kayıtlı eşya **When** adın bir kısmı aranır **Then** eşya ve konumu listelenir | MVP | Onaylandı | — |
| FR-034 | Servis ve bakım kayıtları | — | Sonraki | Taslak | — |

### Ortak alışveriş listesi

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-040 | Ortak listeye ürün ekleme | **Given** ev üyesi **When** 1–120 karakter adla ürün ekler **Then** ürün listede görünür ve diğer üyelerin cihazında görünür; başka evin üyesi göremez | MVP | Geliştiriliyor | — |
| FR-041 | Ürünü alındı işaretleme ve çıkarma | **Given** listede ürün **When** işaretlenir **Then** "alınanlar"a geçer; geri alınabilir | MVP | Onaylandı | — |
| FR-042 | Alınanı stoğa aktarma | **Given** stok ürünüyle bağlı alınan ürün **When** kullanıcı onaylar **Then** stok hareketi (+miktar) oluşur | MVP | Onaylandı | — |
| FR-043 | Alışveriş tutarını gidere aktarma | **Given** tamamlanan alışveriş **When** tutar girilip onaylanır **Then** ortak gider kaydı oluşur (Market kategorisi) | MVP | Onaylandı | — |
| FR-044 | Çevrimdışı liste kullanımı | **Given** ağ yok **When** ürün eklenir/işaretlenir **Then** yerelde görünür, ağ gelince gönderilir; kullanıcı bekleyen değişikliği görür | MVP | Onaylandı | — |

### Hatırlatıcılar, takvim ve ana sayfa

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-050 | Hatırlatıcı (tek seferlik/tekrarlayan) ve yerel bildirim | **Given** bildirim izni **When** zamanı gelir **Then** bildirim gösterilir; izin yoksa uygulama içi rozet | MVP | Onaylandı | — |
| FR-051 | Bakım/filtre değişimi hatırlatıcısı | **Given** eşya **When** periyot tanımlanır **Then** FR-050 ile hatırlatılır | MVP | Onaylandı | — |
| FR-052 | Ev görevi atama (basit: başlık, atanan, tarih) | **Given** üye **When** görev atar **Then** atanan kişide görünür | MVP | Onaylandı | — |
| FR-053 | Gelişmiş görev yönetimi (puan, rotasyon) | — | Sonraki | Taslak | — |
| FR-060 | Ana sayfa özeti | **Given** ev **When** açılır **Then** aylık bütçe durumu, yaklaşan ödemeler, azalan stoklar, yaklaşan hatırlatıcılar; her blokta loading/error/empty | MVP | Onaylandı | — |
| FR-061 | Aylık aile özeti raporu | — | Sonraki | Taslak | — |

### Akıllı özellikler

| ID | Gereksinim | Kabul kriteri (Given/When/Then) | Öncelik | Durum | Spec |
|----|------------|-------------------------------|---------|-------|------|
| FR-070 | Fiş/fatura tarama: ürünler algılanır, onayla gider + stok hareketi | — | Sonraki | Taslak | — |
| FR-071 | Push ile anlık sunucu bildirimi (üye ekledi/aldı) | — | Sonraki | Taslak | — |
| FR-072 | Ücretli plan (StoreKit) | — | Belki | Taslak | — |

## Non-functional requirements

| ID | Alan | Geçerli? | Hedef | Doğrulama |
|----|------|----------|-------|-----------|
| NFR-PERF | Performans bütçesi | E | Cold start < 1,5 s (iPhone 15 sınıfı); yerel listeden ilk çizim < 200 ms; API p95 < 400 ms (AB) | Instruments ölçümü her release; Supabase log p95 |
| NFR-SEC | Güvenlik | E | OWASP MASVS-L1; tüm tablolarda RLS açık; token yalnızca Keychain; davet tokenı hash'li, tek kullanımlık, 72 sa; service-role anahtarı istemcide yok | pgTAP RLS testleri (`make verify-db`); `make verify-security` (gitleaks) |
| NFR-PRIV | Gizlilik (KVKK/GDPR) | E | PII envanteri overview'da; veri AB bölgesinde; hesap silme ≤ 30 gün; log/analitikte PII yok; fotoğraf EXIF konumu silinir; `PrivacyInfo.xcprivacy` güncel | Kod incelemesi + RLS testleri + hesap silme testi |
| NFR-A11Y | Erişilebilirlik | E | VoiceOver etiketleri, Dynamic Type (AX5'e kadar kırılmadan), kontrast WCAG 2.2 AA | Model testleri + simülatörde Accessibility Inspector, release öncesi |
| NFR-I18N | i18n / l10n | E | tr + en; tüm arayüz metinleri modül String Catalog'larında (`Localizable.xcstrings`); tarih/para `FormatStyle` ile, TRY | Unit test: her catalog anahtarının tr ve en çevirisi var (`LocalizationTests`) |
| NFR-OBS | Gözlemlenebilirlik | E | `os.Logger` yapısal log, PII `.private`; crash raporu (Xcode Organizer/TestFlight); sunucu hataları Supabase loglarında correlation id ile | Release öncesi log incelemesi |
| NFR-OFF | Offline / sync | E | Tüm okumalar offline; yazmalar outbox kuyruğunda, ağ gelince idempotent gönderim; metin alanında sunucu zamanıyla son yazan kazanır; stok delta ile birleşir | Sync motoru unit testleri + çakışma senaryosu entegrasyon testi |
| NFR-REC | Hata / kurtarma (RPO/RTO) | E | RPO ≤ 24 sa (Supabase günlük yedek), RTO ≤ 8 sa; her yazma istemci üretimli UUID ile idempotent | Yedekten geri yükleme provası (runbook) beta öncesi |
| NFR-VER | Sürümleme / geri uyumluluk | E | DB migration'ları geriye uyumlu (expand → migrate → contract); en eski desteklenen app sürümü sunucuda zorlanır; SemVer | Migration incelemesi; `make verify-db` temiz kurulumda tüm migration'ları uygular |
| NFR-COST | Maliyet | E | Beta ≤ 50 $/ay (Supabase Pro 25 $ + depolama) | Aylık fatura kontrolü |
| NFR-SCALE | Ölçek | E | İlk yıl ≤ 1.000 hane, hane başına ≤ 10 üye, ≤ 50k kayıt; ev başına depolama ≤ 1 GB | Liste sorguları sayfalı (≤ 50) ve indeksli |

## Varsayımlar

| ID | Varsayım | Gerekçe | Etki | Durum |
|----|----------|---------|------|-------|
| A-001 | Çalışma adı "Homeras"; marka sonra | Repo adı; isim araştırması yapılmadı | Düşük | Onaylandı |
| A-002 | Yalnızca iPhone, iOS 26+; tr + en; TRY | Yeni proje; Observation, typed throws ve güncel SwiftUI API'leri | Orta | Onaylandı |
| A-003 | Backend: Supabase (Postgres + RLS + Auth + Storage), AB bölgesi | Teslim hızı, DB seviyesinde tenant izolasyonu, Android SDK | Yüksek | Onaylandı |
| A-004 | Ev = tenant; roller Sahip/Yönetici/Üye; MVP'de kullanıcı tek eve üye ama şema çoklu eve hazır | Taslak §2 | Yüksek | Onaylandı |
| A-005 | Kişisel kayıtları yalnızca sahibi görür (sunucu zorlar); ayrılan üyenin kişisel verisi kendisiyle gider | Taslak §11 açık sorusu | Yüksek | Onaylandı |
| A-006 | KVKK + GDPR; banka entegrasyonu yok; belgeler özel bucket + imzalı kısa ömürlü URL | Finans + belge verisi | Yüksek | Onaylandı |
| A-007 | Offline okuma + yazma kuyruğu; metinde LWW (sunucu zamanı), stokta delta | Marketteki zayıf sinyal | Yüksek | Onaylandı |
| A-008 | Tek geliştirici, son tarih yok, beta ≤ 50 $/ay, MVP'de ödeme yok | Kullanıcı onayı | Orta | Onaylandı |
| A-009 | Başarı: 15 hanelik TestFlight betası, 6. haftada metrikler (vision.md) | Kullanıcı onayı | Orta | Onaylandı |
| A-010 | Walking skeleton'da giriş e-posta OTP ile; Sign in with Apple, Apple Developer Team ID gelince ilk dilimde | Apple girişi imzalı build + Apple Developer hesabı ister | Düşük | Onaylandı |

## Açık sorular

| ID | Soru | Sahip | Hedef tarih | Cevap / Karar |
|----|------|-------|-------------|---------------|
| Q-001 | Nihai ürün adı? Adaylar: HomePlus, FamilyPlus, LifePlus, HomeFlow, Nestory, Homeras; marka ve alan adı uygunluğu araştırılmadı | Doğancan | TestFlight betası öncesi | — |
| Q-002 | Hangi özellikler ücretsiz, hangileri ücretli? (FR-072) | Doğancan | Beta sonrası | — |
| Q-003 | Fiş tarama yöntemi: cihaz üstü (Vision) mı, sunucu/3. parti OCR mı? (FR-070) | Doğancan | FR-070 intake'i | — |
| Q-004 | Stok takibinde manuel yükü azaltmanın ilk yolu ne olacak? (FR-024/025/070) | Doğancan | Beta 6. hafta verisiyle | — |
| Q-005 | Apple Developer Team ID ve bundle id (`com.<?>.homeras`) | Doğancan | FR-002 dilimi | — |
| Q-006 | Üretim Supabase projesi kimin hesabında, hangi organizasyonda açılacak? | Doğancan | İlk TestFlight build'i | — |
| Q-007 | Uygulamanın UX'i ve bilgi mimarisi (sekme yapısı, ana sayfa, ekran akışları, görsel dil) ne olacak? Önce tıklanabilir prototip yapılıp üzerinde konuşulacak. Walking skeleton ekranları teknik iskelettir, UX onayı yoktur. Başlangıç girdisi (ilk taslak): beş ana ekran: Ana Sayfa (aylık bütçe, yaklaşan ödemeler, azalan stoklar), Finans (gelir/gider, bütçe, kategori, analiz), Ev (envanter, demirbaş, konum, stok), Alışveriş (ortak ve tamamlanan listeler), Aile (üyeler, görevler, takvim, ev ve hesap ayarları) | Doğancan | Bir sonraki ekran dilimi başlamadan önce | — |

## Kapsam dışı

- Banka/kart entegrasyonu, otomatik içe aktarma.
- Çoklu para birimi, Android, iPad, Apple Watch.
- Ödeme ve abonelik akışları (MVP).
- Sunucu push bildirimleri (MVP'de yalnızca yerel bildirim; FR-071 Sonraki).
