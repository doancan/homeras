# Homeras

Ailelerin evin finansını, stoklarını, eşyalarını, ortak alışverişini ve hatırlatıcılarını tek bir
iPhone uygulamasında yönettiği platform. Native iOS 26+ (Swift 6, SwiftUI) ve Supabase (AB).

## Çalıştırma

Gereksinimler: Xcode 27.2, Docker ve `brew install xcodegen supabase/tap/supabase gitleaks`.

```sh
make setup && make db-start && make local-config
make run       # simülatörde aç
make verify    # tüm kalite kapıları
```

Yerel giriş kodları Mailpit'e düşer: http://127.0.0.1:54724

## Dokümantasyon

Ürün, mimari, kararlar ve çalışma kuralları için [docs/README.md](docs/README.md) dosyasına bakın.
