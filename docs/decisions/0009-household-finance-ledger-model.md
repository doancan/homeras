# 0009. Ev finansını hesap, işlem ve paylaşım satırlarından oluşan bir defter olarak modelle

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

Prototip incelemesinde (ebeveyn, mali müşavir ve fintech tasarımcısı profilleri) üç hata öne
çıktı. Kart harcaması gider sayılıp ekstre ödemesi de "ödendi" denince aynı para iki kez sayılıyor.
"Günde harcanabilir" tutarı maaş gününü ve yaklaşan ödemeleri yok sayıyor. Kişisel/ortak ayrımı
tek bir bayrak; "ortak gideri kim ödedi, kim kime borçlu" modellenemiyor. Türkiye'de kart, taksit,
ekstre döngüsü ve birden fazla maaş günü ailelerin gündelik gerçeği.

## Karar

Finans verisi değişmez olay kayıtlarından oluşan bir defterdir. Tutarlar kuruş cinsinden tam sayı
(`bigint`) ve para birimi ile saklanır; bakiye hesaplanan değerdir, saklanmaz.

- **Account:** vadesiz, nakit, kredi kartı (limit, hesap kesim günü, son ödeme ofseti), birikim,
  altın/döviz. Her hesabın sahibi ve görünürlüğü vardır.
- **Transaction:** hesap, tarih, tutar, işyeri, kaynak (elle / SMS / kısayol), `dedup_key`.
  Düzeltme yeni bir olaydır; geçmiş satır değişmez.
- **Split:** bir işlem → N satır (kategori, bütçe kapsamı, tutar, ödeyen üye). Bütçe ve raporlar
  yalnızca split'ler üzerinden hesaplanır.
- **Gider bir kez tanınır:** kart harcaması harcandığı anda gider olur. Ekstre ödemesi, ATM
  çekimi ve eşler arası gönderim **Transfer**'dir; gider ya da gelir sayılmaz. İade, orijinal
  işleme bağlanır ve onun döneminden düşer.
- **InstallmentPlan:** ana tutar, taksit sayısı, vade farkı; kuruş artığı ilk taksite eklenir.
  Taksitler kartın hesap kesim döngüsüne göre ekstreye ve bütçeye yazılır.
- **Statement:** kart, dönem, kesim ve son ödeme tarihi, toplam, asgari tutar; ödemeler Transfer
  olarak bağlanır.
- **RecurringRule:** tekrar kuralı ve tutar modeli (sabit / aralık / mevsimsel). Beklenen ödeme
  gelen işlemle eşleşince kapanır; ikinci kez gider yazılmaz.
- **IncomeSource:** üye, tutar, gün kuralı (hafta sonu/tatilde bir önceki iş günü).
- **Görünürlük:** `household` (ortak), `partners` (yetişkin üyeler), `private` (yalnızca sahibi).
  Sunucu RLS ile zorlar; `private` satırlar ortak toplamlara da girmez (ADR-0004'ü genişletir).
- **Settlement:** split'in ödeyeni ile bütçe kapsamı farklı olduğunda "kim kime borçlu" oluşur;
  hesaplaşma bir Transfer'dir.

**Güvenle harcanabilir** = dönem başı kalan + dönem içi beklenen gelir − dönem içinde vadesi gelen
ekstre, fatura, taksit ve birikim taahhüdü − tampon; bir sonraki gelir gününe kalan güne bölünür.

## Alternatifler

- **Tek "harcama" tablosu + ödendi bayrağı:** basit ama çifte sayım ve ekstre döngüsünü çözemez.
- **Muhasebe defteri (çift taraflı kayıt) tam haliyle:** doğru ama kullanıcı dilinden uzak ve
  MVP için ağır; yukarıdaki model gerektiğinde ona evrilebilir.

## Sonuçlar

- **Olumlu:** çifte sayım yok, ekstre ve taksit gerçeğe uygun, eşler arası hesaplaşma mümkün.
- **Olumsuz / maliyet:** daha çok tablo ve senkronizasyon kuralı; pgTAP ve model testleri zorunlu.
- **Takip:** `docs/product/features/household-finance.md`; FR-016…FR-019, FR-073…FR-079.
