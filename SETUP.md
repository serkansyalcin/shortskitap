# KitapLig — RevenueCat & AdMob Kurulum Rehberi

## İçindekiler
1. [Genel Bakış](#genel-bakış)
2. [RevenueCat Kurulumu](#revenuecat-kurulumu)
3. [Google AdMob Kurulumu](#google-admob-kurulumu)
4. [Google Play Console Ürünleri](#google-play-console-ürünleri)
5. [App Store Connect Ürünleri](#app-store-connect-ürünleri)
6. [Yapılandırma Dosyaları](#yapılandırma-dosyaları)
7. [Production Kontrol Listesi](#production-kontrol-listesi)

---

## Genel Bakış

### Fiyatlandırma

| Plan | Fiyat | Notlar |
|---|---|---|
| Aylık | ₺14,99 / ay | Otomatik yenileme |
| Yıllık | ₺99,99 / yıl | 7 ay bedava, %44 tasarruf |
| Ömür Boyu | ₺299,99 | Tek seferlik ödeme |

### RevenueCat Ürün ID'leri

| Değişken | Değer |
|---|---|
| `RC_PRODUCT_MONTHLY` | `kitaplig_premium_monthly` |
| `RC_PRODUCT_YEARLY` | `kitaplig_premium_yearly` |
| `RC_PRODUCT_LIFETIME` | `kitaplig_premium_lifetime` |
| `RC_ENTITLEMENT` | `premium` |

> Bu ID'ler Google Play Console, App Store Connect **ve** RevenueCat'te birebir aynı olmalıdır.

---

## RevenueCat Kurulumu

### Adım 1 — Hesap Aç & Proje Oluştur

1. [app.revenuecat.com](https://app.revenuecat.com) → **Sign Up**
2. **New Project** → Proje adı: `KitapLig`
3. Sol menüden projeye gir

---

### Adım 2 — Uygulamaları Ekle

**Android:**

1. Sol menü → **Apps** → **+ New App** → **Google Play Store**
2. **App Bundle ID:** `kitaplig`
3. **Google Play Service Credentials JSON** yükle:
   - Google Play Console → Kurulum → API erişimi → Service Account oluştur
   - Oluşturulan hesaba **Finansal veriler** izni ver
   - JSON anahtarı indir ve RevenueCat'e yükle
4. **Save**

**iOS:**

1. **+ New App** → **App Store**
2. **App Bundle ID:** `kitaplig`
3. **In-App Purchase Key** yükle:
   - App Store Connect → Kullanıcılar ve Erişim → Anahtarlar → In-App Purchase
   - Anahtar oluştur ve `.p8` dosyasını indir
   - Key ID ve Issuer ID'yi de not al
4. **Save**

---

### Adım 3 — Ürünleri Oluştur

Sol menü → **Products** → **+ New Product**

> ⚠️ Ürünleri ekleyebilmek için önce Google Play ve App Store'da oluşturulmuş olmaları gerekir (Adım 4 ve 5'e bakın), sonra buraya gelin.

| Identifier | Store | Tür |
|---|---|---|
| `kitaplig_premium_monthly` | Her iki store | Subscription |
| `kitaplig_premium_yearly` | Her iki store | Subscription |
| `kitaplig_premium_lifetime` | Her iki store | Non-Consumable / One-Time |

---

### Adım 4 — Entitlement Oluştur

Sol menü → **Entitlements** → **+ New Entitlement**

| Alan | Değer |
|---|---|
| Identifier | `premium` |
| Display Name | KitapLig Premium |

Oluşturduktan sonra **Attach** → yukarıdaki 3 ürünü de seç → **Save**

---

### Adım 5 — Offering Oluştur

Sol menü → **Offerings** → **+ New Offering**

| Alan | Değer |
|---|---|
| Identifier | `default` |
| Description | KitapLig Premium Plans |

**+ Add Package** ile 3 paket ekle:

| Package Identifier | Type | Ürün |
|---|---|---|
| `$rc_monthly` | Monthly | kitaplig_premium_monthly |
| `$rc_annual` | Annual | kitaplig_premium_yearly |
| `lifetime` | Lifetime | kitaplig_premium_lifetime |

Bitince **Set as Current Offering** tıkla.

---

### Adım 6 — API Key Al

Sol menü → **Project Settings** → **API Keys**

- **Public API Key** kopyala (format: `sk_...`)
- `.env` dosyasına yaz:

```
REVENUECAT_IOS_API_KEY=sk_buraya_yapistir
```

---

### Adım 7 — Webhook Kur

Sol menü → **Project Settings** → **Integrations** → **Webhooks** → **+ Add Webhook**

| Alan | Değer |
|---|---|
| URL | `https://senindomain.com/api/revenuecat/webhook` |
| Authorization | İstediğin güçlü bir şifre (örn. `gizli-anahtar-123`) |
| Events | Hepsini işaretle |

**Save** → Laravel backend `.env`'e ekle:

```
REVENUECAT_WEBHOOK_SECRET=gizli-anahtar-123
```

---

## Google AdMob Kurulumu

### Adım 1 — Hesap Aç

[admob.google.com](https://admob.google.com) → Google hesabınla giriş → **Başla**

---

### Adım 2 — Uygulamayı Ekle

**Uygulamalar** → **Uygulama Ekle**

**Android için:**
1. Platform: **Android**
2. Google Play'de yayında mı? → **Hayır** (henüz yayında değilse)
3. Uygulama adı: `KitapLig`
4. **Ekle** → çıkan **App ID**'yi kopyala

**iOS için:**
1. Platform: **iOS**
2. Aynı adımlar → **App ID**'yi kopyala

---

### Adım 3 — App ID'leri Yerleştir

**`android/app/src/main/AndroidManifest.xml`** (zaten eklendi, sadece değeri güncelle):

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-BURAYA_ANDROID_APP_ID"/>
```

**`ios/Runner/Info.plist`** (zaten eklendi, sadece değeri güncelle):

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-BURAYA_IOS_APP_ID</string>
```

**`.env`** dosyasını da güncelle:

```
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXX~XXXX
ADMOB_APP_ID_IOS=ca-app-pub-XXXX~XXXX
```

---

### Adım 4 — Reklam Birimi Oluştur

**Uygulamalar** → KitapLig Android → **Reklam Birimleri** → **Reklam Birimi Oluştur**

1. Format: **Banner**
2. Ad: `reader_banner`
3. **Oluştur** → çıkan **Reklam Birimi ID**'yi kopyala

Aynısını iOS için de yap.

**`.env`** dosyasına yaz:

```
ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/ANDROID_BANNER_ID
ADMOB_BANNER_IOS=ca-app-pub-XXXX/IOS_BANNER_ID
```

---

## Google Play Console Ürünleri

1. [Google Play Console](https://play.google.com/console) → Uygulamanı seç
2. Sol menü → **Para Kazanma** → **Ürünler**

**Abonelikler sekmesi → Abonelik Oluştur:**

| Ürün ID | Ad | Fiyat | Dönem |
|---|---|---|---|
| `kitaplig_premium_monthly` | KitapLig Aylık | ₺14,99 | 1 Ay |
| `kitaplig_premium_yearly` | KitapLig Yıllık | ₺99,99 | 1 Yıl |

**Tek seferlik ürünler sekmesi → Ürün Oluştur:**

| Ürün ID | Ad | Fiyat |
|---|---|---|
| `kitaplig_premium_lifetime` | KitapLig Ömür Boyu | ₺299,99 |

> Her ürünü oluşturduktan sonra **Etkinleştir** butonuna tıklamayı unutma.

---

## App Store Connect Ürünleri

1. [App Store Connect](https://appstoreconnect.apple.com) → Uygulamanı seç
2. Sol menü → **Uygulama İçi Satın Almalar**

**+ Ekle:**

| Tür | Ürün ID | Referans Adı | Fiyat |
|---|---|---|---|
| Auto-Renewable Subscription | `kitaplig_premium_monthly` | KitapLig Aylık | ₺14,99 |
| Auto-Renewable Subscription | `kitaplig_premium_yearly` | KitapLig Yıllık | ₺99,99 |
| Non-Consumable | `kitaplig_premium_lifetime` | KitapLig Ömür Boyu | ₺299,99 |

Her ürün için:
- Lokalizasyon ekle (TR — Türkçe açıklama yaz)
- **Onaya Gönder** (inceleme için)

Abonelikler için ayrıca:
- **Abonelik Grubu** oluştur: `KitapLig Premium`
- Her iki aboneliği bu gruba ekle

---

## Yapılandırma Dosyaları

### Flutter `.env`

```env
API_BASE_URL=https://senindomain.com/api

# RevenueCat
REVENUECAT_IOS_API_KEY=sk_BURAYA_PUBLIC_KEY

RC_PRODUCT_MONTHLY=kitaplig_premium_monthly
RC_PRODUCT_YEARLY=kitaplig_premium_yearly
RC_PRODUCT_LIFETIME=kitaplig_premium_lifetime
RC_ENTITLEMENT=premium

# Fallback fiyatlar (RC yüklenemediğinde gösterilir)
PRICE_MONTHLY=₺14,99
PRICE_YEARLY=₺99,99
PRICE_LIFETIME=₺299,99

# AdMob
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXX~XXXX
ADMOB_APP_ID_IOS=ca-app-pub-XXXX~XXXX
ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/XXXX
ADMOB_BANNER_IOS=ca-app-pub-XXXX/XXXX
```

### Laravel `.env` (ek satırlar)

```env
REVENUECAT_WEBHOOK_SECRET=webhook_sifren_buraya
REVENUECAT_IOS_API_KEY=sk_BURAYA_SECRET_KEY
```

---

## Production Kontrol Listesi

### Backend
- [ ] `php artisan migrate` çalıştırıldı (subscriptions, advertisements tabloları)
- [ ] `REVENUECAT_WEBHOOK_SECRET` production `.env`'e girildi
- [ ] RevenueCat webhook URL'si production domain'e güncellendi

### Flutter
- [ ] `flutter pub get` çalıştırıldı
- [ ] `AndroidManifest.xml`'de gerçek AdMob App ID girildi
- [ ] `Info.plist`'te gerçek AdMob App ID girildi
- [ ] `.env`'de gerçek `REVENUECAT_IOS_API_KEY` girildi
- [ ] `.env`'de gerçek `ADMOB_BANNER_ANDROID` ve `ADMOB_BANNER_IOS` girildi
- [ ] API_BASE_URL production adresine güncellendi

### RevenueCat Paneli
- [ ] Android ve iOS uygulamaları eklendi
- [ ] Service Credentials yüklendi (Android)
- [ ] In-App Purchase Key yüklendi (iOS)
- [ ] 3 ürün eklendi
- [ ] `premium` entitlement oluşturuldu ve ürünlere bağlandı
- [ ] `default` offering oluşturuldu, 3 paket eklendi, current olarak işaretlendi
- [ ] Webhook kuruldu

### Google Play Console
- [ ] `kitaplig_premium_monthly` aboneliği oluşturuldu ve etkinleştirildi
- [ ] `kitaplig_premium_yearly` aboneliği oluşturuldu ve etkinleştirildi
- [ ] `kitaplig_premium_lifetime` tek seferlik ürünü oluşturuldu ve etkinleştirildi

### App Store Connect
- [ ] `kitaplig_premium_monthly` aboneliği oluşturuldu
- [ ] `kitaplig_premium_yearly` aboneliği oluşturuldu
- [ ] `kitaplig_premium_lifetime` Non-Consumable ürünü oluşturuldu
- [ ] Abonelik grubu oluşturuldu
- [ ] Tüm ürünler onaya gönderildi

### AdMob
- [ ] Android uygulaması eklendi, App ID alındı
- [ ] iOS uygulaması eklendi, App ID alındı
- [ ] Android banner reklam birimi oluşturuldu
- [ ] iOS banner reklam birimi oluşturuldu
