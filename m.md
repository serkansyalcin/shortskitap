# Sosyal Giris Durumu ve Sonraki Adimlar

Bu projede sosyal giris icin temel UI vardi ama backend guvenligi eksikti. Onu tamamladim:

- Flutter artik backend'e sadece `provider_id` gondermiyor.
- Google icin `access_token` ve varsa `id_token` gonderiliyor.
- Apple icin `identity_token` ve `authorization_code` gonderiliyor.
- Laravel backend Google/Apple tarafinda token dogrulamasi yapmadan kullanici olusturmuyor.

## Su an kodda ne degisti?

Flutter:

- `lib/features/auth/widgets/social_auth_buttons.dart`
  Google girisinde Google'dan auth token aliniyor.
  Apple girisinde `identityToken` backend'e gidiyor.
- `lib/core/services/auth_service.dart`
  `/auth/social` istegi token bazli hale getirildi.

Backend:

- `shortskitap-api/app/Http/Controllers/Api/Auth/SocialAuthController.php`
  Artik gelen sosyal auth istegi bir servis uzerinden dogrulaniyor.
- `shortskitap-api/app/Services/SocialAuthService.php`
  Google ve Apple token dogrulama mantigi eklendi.
- `shortskitap-api/config/services.php`
  Apple/Google sosyal auth config alanlari eklendi.
- `shortskitap-api/.env.example`
  Gerekli ornek env degerleri eklendi.
- `ios/Runner/Runner.entitlements`
  Apple Sign In capability icin entitlement dosyasi eklendi.

## Backend gerekli miydi?

Evet, gerekliydi.

Eski yapida mobil uygulama `email`, `name`, `provider_id` gonderip backend tarafinda direkt hesap acabiliyordu. Bu guvenli degildi; teoride biri gercek Google/Apple oturumu olmadan da sahte istek gonderebilirdi.

Yeni yapida backend:

- Google token'ini Google'a soruyor.
- Apple `identity_token` imzasini Apple public keys ile dogruluyor.
- Sonra kullaniciyi olusturuyor veya guncelliyor.

## Firebase gerekli mi?

Kisa cevap: zorunlu degil.

Bu proje su an Firebase Authentication kullanmiyor. Dogrudan:

- Flutter `google_sign_in`
- Flutter `sign_in_with_apple`
- Laravel backend token dogrulama

akisiyla ilerliyor.

Yani sadece login icin Firebase Auth kurmak zorunda degilsin.

Ama Google Sign-In iOS yapilandirmasinda Firebase Console kullanmak isini kolaylastirir; cunku iOS client ID ve reversed client ID bilgilerini oradan alirsin.

## Firebase tarafinda ne yapmalisin?

Google Sign-In icin:

1. Firebase Console'da proje ac.
2. iOS app ekle: bundle id `com.kitaplig.app`.
3. Android app ekle: package `com.kitaplig.app`.
4. Authentication > Sign-in method > Google'i enable et.
5. iOS icin `GoogleService-Info.plist` indir.
6. Bu dosyadaki degerlerden sunlari kullan:
   `CLIENT_ID`
   `REVERSED_CLIENT_ID`
7. Web client / server client id gerekiyorsa Google provider icindeki Web client bilgisini al.

Not:

- Bu projede Firebase Auth SDK'si kullanmiyoruz.
- Firebase burada daha cok Google OAuth client bilgilerini almak ve konsoldan provider acmak icin yararli.

## Flutter tarafinda manuel tamamlaman gerekenler

### 1. Flutter `.env`

`shortskitap/.env` icine sunu ekle:

```env
GOOGLE_SERVER_CLIENT_ID=buraya_google_web_client_id
```

Bu alan zorunlu olarak her durumda patlamaz ama backend'e guvenilir Google token iletmek icin eklemen iyi olur.

### 2. iOS Info.plist

Google girisinin iOS'ta calismasi icin [Info.plist](c:/xampp/htdocs/shortskitap/ios/Runner/Info.plist) dosyasina Google tarafindan gelen client bilgilerini eklemelisin.

Eklenmesi gereken mantik:

```xml
<key>GIDClientID</key>
<string>IOS_CLIENT_ID</string>
<key>GIDServerClientID</key>
<string>WEB_CLIENT_ID</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Buradaki degerler `GoogleService-Info.plist` dosyasindan gelir.

### 3. Xcode Sign in with Apple capability

Kod tarafinda entitlement ekledim ama Xcode'da da kontrol etmelisin:

1. `ios/Runner.xcworkspace` ac
2. Runner > Signing & Capabilities
3. `Sign in with Apple` capability ekli mi kontrol et
4. Apple Developer hesabinda ilgili App ID icin capability acik olsun
5. Provisioning profile yenilenmis olsun

## Apple tarafinda ne yapmalisin?

Senin mevcut kodunda Apple butonu Android'de gosterilmiyor, yani su an iOS odakli bir Apple login akisi var. Bu senaryo icin temel gereksinimler:

1. Apple Developer paid account
2. App ID: `com.kitaplig.app`
3. App ID uzerinde `Sign in with Apple` capability
4. Xcode signing/provisioning guncel

Bu projede simdilik Apple icin backend tarafinda `identity_token` dogrulamasi yapiliyor. Bu login icin yeterli.

Daha ileri seviye senaryo:

- Apple authorization code exchange
- refresh token saklama
- revoked credential kontrolu

Bunlar istersen ikinci adim olarak eklenebilir.

## Laravel backend env tarafinda ne yapmalisin?

`shortskitap-api/.env` icine gerekirse sunu ekleyebilirsin:

```env
APPLE_AUTH_ALLOWED_AUDIENCES=com.kitaplig.app
```

Eger ileride web veya Android uzerinden Apple login yaparsan, bu audience listesine Apple Service ID de eklenmeli.

## Veritabani yeterli mi?

Evet, mevcut tablo yapisi sosyal giris icin temel olarak yeterli:

- `provider`
- `provider_id`
- `avatar_url`
- `email_verified_at`

Ama su siniri bil:

Mevcut `users` tablosu tek kullanici icin tek sosyal provider modeliyle calisiyor. Yani ayni kullaniciya hem Google hem Apple baglama gibi coklu provider mimarisi yok.

Eger bunu istersen ileride ayri bir `user_social_accounts` tablosu kurmak daha dogru olur.

## Su an senden beklenen net adimlar

1. Firebase Console'da Google provider'i ac.
2. iOS ve Android app kayitlarini yap.
3. iOS icin `GoogleService-Info.plist` icinden `CLIENT_ID` ve `REVERSED_CLIENT_ID` bilgilerini al.
4. [Info.plist](c:/xampp/htdocs/shortskitap/ios/Runner/Info.plist) dosyasina bu degerleri ekle.
5. Flutter `.env` icine `GOOGLE_SERVER_CLIENT_ID` koy.
6. Xcode'da `Sign in with Apple` capability aktif oldugunu kontrol et.
7. Backend `.env` icinde `APPLE_AUTH_ALLOWED_AUDIENCES=com.kitaplig.app` oldugunu kontrol et.
8. Sonra fiziksel iPhone veya uygun test cihazinda Google ve Apple login'i ayri ayri test et.

## Onemli eksik / dikkat noktalar

- [Info.plist](c:/xampp/htdocs/shortskitap/ios/Runner/Info.plist) icinde Google Sign-In iOS anahtarlari henuz yok.
- Firebase Auth SDK projede kurulu degil; bu bilincli bir tercih olabilir.
- Apple login'de tam revocation / refresh token akisi henuz yok.
- Coklu sosyal hesap baglama mimarisi henuz yok.

## Son soz

Eger hedefin:

- sadece mobil login calissin
- Laravel kendi token'ini uretsin
- Firebase sadece Google setup yardimcisi olsun

ise su anki yapi dogru yonde.

Eger istersen bir sonraki adimda ben senin icin:

- `ios/Runner/Info.plist` Google ayarlarini placeholder'larla ekleyebilirim
- Flutter `.env.example` olusturabilirim
- sosyal login icin test senaryolari yazabilirim
- `user_social_accounts` tablosuna gecen daha temiz mimariyi de kurabilirim
