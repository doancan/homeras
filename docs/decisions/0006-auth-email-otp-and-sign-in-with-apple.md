# 0006. Kimlik doğrulama: e-posta OTP + Sign in with Apple (Supabase Auth)

- **Durum:** Kabul
- **Tarih:** 2026-11-20

## Bağlam

FR-001 ve FR-002 iki giriş yolu istiyor. Parola, kullanıcı ve güvenlik yükü getirir. App Store,
üçüncü taraf giriş sunulduğunda Sign in with Apple ister. Sign in with Apple imzalı build ve Apple
Developer Team ID gerektirir (Q-005).

## Karar

- Parolasız giriş: e-postaya gönderilen 6 haneli, 10 dakika geçerli, tek kullanımlık kod
  (`signInWithOTP` + `verifyOTP(type: .email)`). Kod yeniden isteme en sık 60 saniyede bir.
- Sign in with Apple, Team ID gelince native `ASAuthorizationController` + Supabase `signInWithIdToken` ile.
- Kullanıcı varlığı sızdırılmaz: kod isteği var olan ve olmayan e-posta için aynı yanıtı verir;
  yanlış ve süresi dolmuş kod aynı genel hatayı gösterir.
- Oturum (access + refresh token) yalnızca Keychain'de (supabase-swift `KeychainLocalStorage`)
  tutulur. Refresh token rotasyonu açıktır. Hesap silmede ve çıkışta oturumlar global iptal edilir.
- Hız sınırları Supabase Auth'ta (IP bazlı) ve e-posta başına `max_frequency` ile uygulanır.

## Alternatifler

- **E-posta + parola:** parola sıfırlama akışı, zayıf parola riski ve ek ekranlar.
- **Magic link:** e-postadaki bağlantı başka cihazda açılabilir; universal link kurulumu gerekir.
  Kod girişi aynı cihazda kalır ve `textContentType(.oneTimeCode)` ile otomatik dolar.

## Sonuçlar

- **Olumlu:** parola saklanmaz; tek ekranlık, hızlı giriş.
- **Olumsuz / maliyet:** üretimde özel SMTP (ör. AB bölgeli sağlayıcı) gerekir; Supabase'in yerleşik
  e-postası saatlik sınırlıdır.
- **Takip:** üretim SMTP sağlayıcısı FR-002 dilimiyle seçilir; overview.md auth akışı.
