# Ürün Vizyonu: Homeras

> Son güncelleme: 2026-11-20 · Sahip: Doğancan (ürün sahibi)

Homeras, bir ailenin evinin finansını, stoklarını, eşyalarını, alışveriş ihtiyaçlarını ve
düzenli sorumluluklarını tek bir iOS uygulamasında birleştirir. Temel prensip: kullanıcıya
mümkün olduğunca az veri girdirerek zaman ve para kazandırmak.

**Ürün felsefesi:** Daha az uğraş, daha düzenli bir ev, daha kontrollü bir bütçe.

## Problem

Aileler evin bütçesini, evde ne kaldığını, eşyaların nerede olduğunu ve kimin ne alacağını
ayrı uygulamalara, not defterlerine ve hafızaya dağıtıyor. Bu parçalar birbirine bağlı
olmadığı için aynı ürün iki kez alınıyor, biten ürün fark edilmiyor, garanti belgesi ya da
HDMI kablosu arandığında bulunamıyor ve ay sonunda paranın nereye gittiği bilinmiyor.

## Hedef kullanıcılar

- **Birincil:** Ortak evi yöneten çift ya da aile yetişkinleri (25–50 yaş, iPhone kullanıcısı,
  orta teknik seviye). Evi kurar, üyeleri davet eder, bütçeyi takip eder.
- **İkincil:** Eve davet edilen diğer yetişkin üyeler (eş, ev arkadaşı, yetişkin çocuk).
  Çoğunlukla alışveriş listesi ve stok güncellemesi yapar.

## Ana iş (Job-to-be-done)

"Evde bir şey bittiğinde, alındığında ya da ödendiğinde bunu tek dokunuşla kaydetmek
istiyorum, böylece ailemle aynı resmi görüp gereksiz alışveriş ve unutulan ödeme olmasın."

## Değer önerisi

- **Bağlı modüller:** Alışveriş listesinde işaretlenen ürün stoğa ve bütçeye tek onayla
  aktarılır; azalan stok listeye öneri olarak düşer. Ayrı uygulamalar bunu yapmaz.
- **Ortak ama mahrem:** Ev verisi ortak; kişisel harcamalar yalnızca sahibine görünür.
- **Az veri girişi:** Varsayılanlar, öneriler ve tek dokunuşluk aksiyonlar.

## Platformlar

- iPhone, iOS 26+ (native Swift/SwiftUI). iPad ve Apple Watch sonraki sürümlerde.
- Backend istemciden bağımsız API'dir; Android istemcisi sonradan eklenebilir.
- Arayüz dili Türkçe ve İngilizce; para birimi TRY (tek para birimi).

## Başarı metrikleri

| Metrik | Hedef | Ölçüm yöntemi | Tarih |
|--------|-------|---------------|-------|
| Haftalık aktif hane | Beta hanelerinin ≥ %50'si haftada ≥ 3 gün aktif | Sunucuda hane bazında günlük aktiflik sayımı (PII'siz) | Betanın 6. haftası |
| Ortak kullanım | Hanelerin ≥ %60'ı ortak alışveriş listesini ≥ 2 üyeyle kullanıyor | Listeye yazan farklı üye sayısı / hane | Betanın 6. haftası |
| Beta büyüklüğü | 15 hane TestFlight kapalı betasında | TestFlight + sunucu hane sayısı | Beta başlangıcı |

## İlk dilim (MVP)

- **Walking skeleton:** E-posta ile giriş → ev oluştur → ortak alışveriş listesine ürün ekle →
  liste sunucudan okunup görüntülenir (ikinci üye aynı listeyi görür).
- **MVP FR'ler:** FR-001…FR-007 (hesap, ev ve üyelik), FR-010…FR-014 (finans), FR-020…FR-023
  (stok), FR-030…FR-033 (envanter), FR-040…FR-044 (alışveriş), FR-050…FR-052 (hatırlatıcılar),
  FR-060 (ana sayfa). Ayrıntı: [requirements.md](requirements.md).

## Kapsam dışı (Non-goals)

- Banka/kart entegrasyonu ve otomatik harcama içe aktarma: KVKK ve güven yükü MVP'yi aşar.
- Otomatik fiş/fatura okuma, NFC/QR/fiziksel buton ile stok düşme: değer doğrulanmadan
  otomasyon yatırımı yapılmaz (Sonraki).
- Tüketim tahmini, finansal öngörü, tasarruf önerileri, aylık aile özeti (Sonraki).
- Çocuk hesapları ve gelişmiş görev yönetimi (Sonraki).
- Birden fazla ev yönetimi (veri modeli hazır, arayüz Sonraki), Android uygulaması, iPad/Watch.
- Ödeme, abonelik ve freemium: MVP'de para akışı yok.
- Çoklu para birimi.

## Kısıtlar

- Ekip: tek geliştirici. Kesin son tarih yok; teslim hızı performans optimizasyonundan önce gelir.
- Beta dönemi altyapı tavanı ≤ 50 $/ay.
- KVKK ve GDPR geçerlidir; veri AB bölgesinde (Frankfurt) tutulur.
- App Store kuralları: uygulama içinden hesap silme, Sign in with Apple (üçüncü taraf girişle birlikte).
- Ürün adı "Homeras" çalışma adıdır; marka kararı açık soru (Q-001).
