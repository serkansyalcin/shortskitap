# KitapLig — Mağaza Yayın Kontrol Listesi

## Uygulama Bilgileri
- **Uygulama Adı**: KitapLig
- **Bundle ID (iOS)**: com.kitaplig.app
- **Application ID (Android)**: com.kitaplig.app
- **Versiyon**: 1.0.0 (Build 1)

---

## Android (Google Play Store)

### Teknik Hazırlık
- [ ] `keystore.jks` dosyası oluşturuldu ve `android/app/` altına koyuldu
- [ ] `android/key.properties` dosyası oluşturuldu:
  ```
  storePassword=<şifre>
  keyPassword=<şifre>
  keyAlias=kitaplig
  storeFile=../app/keystore.jks
  ```
- [ ] `build.gradle.kts` içinde `signingConfigs` release keystore ile güncellendi
- [ ] `flutter build apk --release` veya `flutter build appbundle --release` başarıyla çalıştı

### Play Console Gereksinimleri
- [ ] Uygulama simgesi (512x512 PNG) yüklendi
- [ ] Feature Graphic (1024x500 PNG) hazırlandı
- [ ] Ekran görüntüleri (Phone: min 2, Tablet: min 1)
- [ ] Kısa açıklama (max 80 karakter) girildi
- [ ] Tam açıklama (max 4000 karakter) girildi
- [ ] Gizlilik politikası URL'si: https://kitaplig.com/privacy
- [ ] Uygulama kategorisi: **Kitaplar & Referans**
- [ ] İçerik derecelendirmesi anketi dolduruldu (Herkes için — E)
- [ ] Hedef kitle belirlendi (13+)

---

## iOS (Apple App Store)

### Teknik Hazırlık
- [ ] Apple Developer hesabı aktif
- [ ] App Store Connect'te yeni uygulama oluşturuldu (Bundle ID: com.kitaplig.app)
- [ ] Xcode ile signing certificate ve provisioning profile ayarlandı
- [ ] `flutter build ios --release` başarıyla çalıştı
- [ ] Xcode ile Archive oluşturuldu ve App Store Connect'e yüklendi

### App Store Connect Gereksinimleri
- [ ] Uygulama simgeleri (AppIcon.appiconset) tam seti hazır
- [ ] Ekran görüntüleri (iPhone 6.9", 6.5", 5.5" zorunlu; iPad Pro 12.9" isteğe bağlı)
- [ ] Uygulama adı: **KitapLig**
- [ ] Altyazı: **Oku, Yarış, Zirveye Çık!**
- [ ] Anahtar kelimeler girildi (max 100 karakter)
- [ ] Açıklama girildi
- [ ] Gizlilik politikası URL'si: https://kitaplig.com/privacy
- [ ] Destek URL'si: https://kitaplig.com/support
- [ ] Kategori: **Kitaplar** (Ana), **Eğitim** (İkincil)
- [ ] Yaş derecelendirmesi: **4+**
- [ ] Fiyat: Ücretsiz (Freemium)
- [ ] "Sign in with Apple" gereksinim kontrolü yapıldı

---

## Uygulama Simgesi Hazırlama

`assets/icons/app_icon.png` dosyasını 1024x1024 çözünürlükte hazırlayın.
Ardından simgeleri otomatik oluşturmak için:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## Yayın Öncesi Test

```bash
# Release APK testi
flutter build apk --release
flutter install --release

# iOS Release testi (macOS gerektirir)
flutter build ios --release
```

---

## Versiyonlama

`pubspec.yaml` içinde versiyon formatı: `MAJOR.MINOR.PATCH+BUILD`
- `versionName` (mağazada gösterilen): `1.0.0`
- `versionCode` (build numarası): `1`

```yaml
version: 1.0.0+1
```
