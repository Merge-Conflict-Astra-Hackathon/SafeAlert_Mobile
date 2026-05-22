# SafeAlert Mobile

Aplikasi Flutter SafeAlert untuk user menerima alarm darurat, mengirim status evakuasi, melihat kontak darurat, dan membuka denah gedung.

## Link

- Backend production: https://safealertweb-production.up.railway.app/
- API base URL: https://safealertweb-production.up.railway.app/api

## Stack

- Flutter
- Firebase Cloud Messaging
- Shared Preferences
- Native Android alert mode untuk suara, getar, brightness, dan volume maksimum

## Firebase Android

Build release membutuhkan file:

```text
android/app/google-services.json
```

Cara mendapatkannya:

1. Buka Firebase Console.
2. Buat atau pilih project SafeAlert.
3. Tambahkan Android app dengan package name:

```text
com.example.safealert_mobile
```

4. Download `google-services.json`.
5. Simpan ke:

```text
SafeAlert_Mobile/android/app/google-services.json
```

## Local Build

Jalankan dari folder `SafeAlert_Mobile`:

```bash
flutter pub get
flutter analyze
flutter build apk --release --dart-define=SAFEALERT_API_URL=https://safealertweb-production.up.railway.app/api
```

Output APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Bitrise Build

Gunakan step **Flutter Build**.

Rekomendasi setting:

```text
Project location: /Users/vagrant/git
Platform: android
Android output type: apk
```

Additional build params:

```bash
--release --dart-define=SAFEALERT_API_URL=https://safealertweb-production.up.railway.app/api
```

Pastikan file `android/app/google-services.json` sudah ada di repository atau dibuat lewat Bitrise Secret sebelum step Flutter Build.

## Catatan Alarm Background

Alarm dapat diterima saat app background/ditutup jika:

- user sudah pernah membuka app dan login/register,
- permission notifikasi diizinkan,
- device memiliki koneksi internet,
- backend menyimpan FCM token yang valid.

Android tidak selalu mengizinkan app membuka layar sendiri dari background tanpa interaksi user. Saat app foreground, SafeAlert dapat menampilkan layar alarm, getar, suara, brightness penuh, dan volume maksimum.

## Deploy Flow

1. Commit perubahan ke branch `main`.
2. Push ke GitHub.
3. Jalankan build APK di Bitrise.
4. Download artifact `app-release.apk`.
