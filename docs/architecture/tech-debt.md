# Teknik borç

Bilinçli olarak kabul edilmiş borçlar. Kayıtsız borç yoktur. Geri ödenen satır silinir; tarihçe
git'te kalır.

| ID | Borç | Etki | Geri ödeme koşulu | Sahibi | Taban dışı? |
|---|---|---|---|---|---|
| TD-001 | Swift entegrasyon testleri (`make verify-integration`) CI'da çalışmıyor; GitHub'ın macOS runner'larında Docker yok. CI yalnızca pgTAP (`verify-db`) ve unit/app testlerini çalıştırıyor | Orta: adapter ile şema arasındaki uyumsuzluk yalnızca yerelde yakalanır | Docker'lı self-hosted macOS runner ya da adapter'ın Linux'ta derlenmesi; en geç ilk TestFlight build'inden önce | Doğancan | H |
| TD-003 | CI, GitHub'ın `macos-26` imajında Xcode 27 olmadığı için en yeni Xcode 26.x ile derliyor; App Store derlemesi (iOS 27 SDK) yalnızca yerelde doğrulanıyor | Orta: iOS 27 SDK'ya özgü bir derleme hatası CI'da yakalanmaz (iOS 26 uyumluluğu ise yakalanır) | GitHub imajına Xcode 27 eklendiğinde CI kendiliğinden geçer; en geç Nisan 2027 App Store şartından önce kontrol edilir | Doğancan | H |
| TD-002 | `NSAllowsLocalNetworking` Release build'inde de açık (yerel Supabase'e HTTP için) | Düşük: yalnızca yerel ağ adreslerine HTTP izni verir | İlk TestFlight build'inden önce anahtar yalnızca Debug yapılandırmasına taşınır | Doğancan | H |
