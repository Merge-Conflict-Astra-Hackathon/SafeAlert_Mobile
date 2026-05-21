# SafeAlert - Dokumentasi Lengkap Sistem

**Sistem Alarm Darurat Multisensori Berbasis Kendali Terpusat**

---

## 📋 Daftar Isi

1. [Ringkasan Proyek](#ringkasan-proyek)
2. [Arsitektur Sistem](#arsitektur-sistem)
3. [Struktur Folder & Komponen](#struktur-folder--komponen)
4. [Teknologi Stack](#teknologi-stack)
5. [Panduan Setup & Instalasi](#panduan-setup--instalasi)
6. [API Endpoints Lengkap](#api-endpoints-lengkap)
7. [Alur Data End-to-End](#alur-data-end-to-end)
8. [Database Schema](#database-schema)
9. [Dashboard Admin](#dashboard-admin)
10. [Aplikasi Mobile](#aplikasi-mobile)
11. [Todo & Roadmap](#todo--roadmap)

---

## 🎯 Ringkasan Proyek

### Visi
SafeAlert adalah platform manajemen **evakuasi darurat yang inklusif** untuk penyandang disabilitas (tunarungu, tunanetra). Platform ini memastikan setiap individu menerima peringatan evakuasi dalam format yang sesuai dengan kebutuhan mereka:
- **Tunarungu**: Getar + Flash + Teks besar
- **Tunanetra**: TTS (Text-to-Speech) + Getar
- **Non-disabilitas**: Semua modalitas

### Scope MVP
- Aplikasi mobile (Flutter) untuk user
- Backend REST API (Django + DRF)
- Dashboard admin web (Django Templates + Bootstrap 5)
- Integrasi Firebase Cloud Messaging (FCM)
- Database user, alarm log, dan konfirmasi

---

## 🏗️ Arsitektur Sistem

### Diagram Komponen
```
┌─────────────────────────────────────────────────────────────┐
│                     SafeAlert Ecosystem                      │
└─────────────────────────────────────────────────────────────┘
                          ▼
      ┌──────────────────────────────────────┐
      │    Firebase Cloud Messaging (FCM)    │
      │    (Push Notification Hub)            │
      └───────────────┬──────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
   [Mobile App]              [Backend Django]
   (Flutter)                 (DRF API)
   • User Registration       • Auth & JWT
   • Receive Alerts          • User Management
   • Confirm Status          • Alarm Trigger
   • Personalized Alert      • FCM Integration
                              • Database (SQLite/PostgreSQL)
                                    │
                                    ▼
                             [Dashboard Admin]
                             (Django Templates)
                             • User Verification
                             • Alarm Control
                             • Real-time Monitoring
```

### Alur Komunikasi
```
1. User Registration:
   Mobile App → Backend API (/api/auth/register/) → Database
   
2. Alarm Trigger:
   Dashboard → Backend → FCM → All Mobile Devices
   
3. Confirmation:
   Mobile App → Backend API (/api/confirm/) → Database → Dashboard (auto-refresh)
   
4. Cancel Alarm:
   Dashboard → Backend → FCM (cancel payload) → Mobile App
```

---

## 📁 Struktur Folder & Komponen

### Backend (`safealert_backend/`)
```
safealert_backend/
├── safealert/                  # Django project config
│   ├── settings.py            # Environment & DB config
│   ├── urls.py                # URL routing
│   └── wsgi.py                # WSGI entry point
│
├── users/                      # User management app
│   ├── models.py              # User model (name, phone, floor, disability_type, fcm_token, admin_status)
│   ├── serializers.py         # DRF serializers
│   ├── views.py               # API views for user registration & status update
│   └── urls.py                # User-related endpoints
│
├── alarms/                     # Alarm management app
│   ├── models.py              # AlarmLog model
│   ├── serializers.py         # AlarmLog serializers
│   ├── views.py               # API views for alarm trigger
│   └── fcm_service.py         # Firebase push notification logic
│
├── confirmations/             # Confirmation tracking
│   ├── models.py              # Confirmation model
│   ├── serializers.py         # Confirmation serializers
│   └── views.py               # API views for status confirmation
│
├── dashboard/                 # Web admin dashboard
│   ├── templates/
│   │   ├── base.html          # Main layout (sidebar + navbar)
│   │   ├── index.html         # Dashboard ringkasan
│   │   ├── verify_users.html  # Verifikasi user pending
│   │   ├── user_list.html     # Daftar user aktif
│   │   └── alarms.html        # Kirim & riwayat alarm
│   ├── views.py               # Django views untuk dashboard
│   ├── urls.py                # Dashboard routing
│   └── static/
│       ├── css/dashboard.css  # Custom styling
│       └── js/               # AJAX & interactivity
│
├── requirements.txt           # Python dependencies
├── manage.py                  # Django management CLI
├── seed_mock_data.py          # Seeder untuk mock data
├── verify_safealert.py        # Verifikasi API endpoints
└── .env                       # Environment variables (Firebase creds, secret key)
```

### Mobile (`safealert_mobile/`)
```
safealert_mobile/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/
│   │   ├── registration_screen.dart    # User registration form
│   │   ├── home_screen.dart           # Standby screen
│   │   ├── alarm_screen.dart          # Fullscreen alarm alert
│   │   └── cancel_screen.dart         # Cancel notification (green screen)
│   ├── services/
│   │   ├── api_service.dart           # HTTP client untuk backend
│   │   ├── fcm_service.dart           # Firebase messaging setup
│   │   └── alert_service.dart         # Getar, flash, TTS logic
│   ├── models/
│   │   └── user_model.dart            # User data structure
│   └── widgets/
│       └── custom_widgets.dart        # Reusable UI components
│
├── android/
│   └── app/
│       ├── google-services.json       # Firebase config
│       └── AndroidManifest.xml        # Permissions (VIBRATE, INTERNET, FLASHLIGHT, etc)
│
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # Setup instructions
```

---

## 🛠️ Teknologi Stack

| Layer | Teknologi | Versi |
|-------|-----------|-------|
| **Frontend Mobile** | Flutter | 3.x |
| **Backend API** | Django REST Framework | 3.14.x |
| **Database** | SQLite (dev) / PostgreSQL (prod) | - |
| **Push Notification** | Firebase Cloud Messaging (FCM) | - |
| **Dashboard Web** | Django Templates + Bootstrap | 5.x |
| **Authentication** | SimpleJWT (JSON Web Token) | 5.x |
| **Python Version** | Python | 3.9+ |
| **Mobile SDK** | Firebase SDK (Flutter) | Latest |

---

## 📦 Panduan Setup & Instalasi

### Prerequisites
```bash
✓ Python 3.9+
✓ pip (package manager)
✓ Git
✓ Flutter SDK (untuk development mobile)
✓ Firebase Console Account (untuk FCM)
```

### 1. Clone Repository
```bash
git clone https://github.com/AvilioWatson/Simulasi_Hackathon_Astra.git
cd Simulasi_Hackathon_Astra
```

### 2. Setup Backend

#### 2.1 Navigasi ke direktori backend
```bash
cd safealert_backend
```

#### 2.2 Buat & aktifkan virtual environment
**Windows:**
```bash
python -m venv .venv
.venv\Scripts\activate
```

**Mac/Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

#### 2.3 Install dependencies
```bash
pip install -r requirements.txt
```

#### 2.4 Setup Firebase credentials (opsional)
- Unduh `firebase-credentials.json` dari Firebase Console
- Letakkan di root `safealert_backend/`

#### 2.5 Inisialisasi database & seed mock data
```bash
python seed_mock_data.py
```

#### 2.6 Jalankan development server
```bash
python manage.py runserver
```

**Server running di:** `http://127.0.0.1:8000`

### 3. Setup Dashboard Admin

#### Akses Dashboard
```
URL: http://127.0.0.1:8000/dashboard/
Username: admin_gedung
Password: password123
```

### 4. Setup Mobile (Opsional untuk Development)

```bash
cd ../safealert_mobile
flutter pub get
flutter run -d <device_id>
```

---

## 📡 API Endpoints Lengkap

### Authentication

#### `POST /api/auth/register/` - User Registration
**Request:**
```json
{
  "name": "Budi Santoso",
  "phone": "081234567890",
  "floor": 7,
  "disability_type": "deaf",
  "fcm_token": "dI9pL7..."
}
```

**Response (201):**
```json
{
  "id": 1,
  "name": "Budi Santoso",
  "phone": "081234567890",
  "floor": 7,
  "disability_type": "deaf",
  "admin_status": "pending",
  "message": "Registrasi berhasil. Menunggu verifikasi admin."
}
```

#### `POST /api/auth/login/` - Admin Login
**Request:**
```json
{
  "username": "admin_gedung",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "token": "jwt_token_here",
  "admin": {
    "id": 1,
    "username": "admin_gedung"
  }
}
```

---

### User Management

#### `GET /api/users/`
**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "count": 50,
  "results": [
    {
      "id": 1,
      "name": "Budi Santoso",
      "phone": "081234567890",
      "floor": 7,
      "disability_type": "deaf",
      "admin_status": "safe",
      "created_at": "2026-05-18T10:00:00Z"
    }
  ]
}
```

#### `PATCH /api/users/{id}/status/` - Update User Status
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "admin_status": "safe"
}
```

**Response (200):**
```json
{
  "id": 1,
  "admin_status": "safe",
  "message": "Status user diperbarui."
}
```

---

### Alarm Management

#### `POST /api/alarms/trigger/` - Trigger Emergency Alarm
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "message": "KEBAKARAN LT. 7. GUNAKAN TANGGA DARURAT TIMUR."
}
```

**Response (201):**
```json
{
  "alarm_id": 123,
  "message": "KEBAKARAN LT. 7...",
  "triggered_at": "2026-05-18T14:32:00Z",
  "total_recipients": 50,
  "status": "active"
}
```

#### `GET /api/alarms/` - Get Alarm History
**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "count": 10,
  "results": [
    {
      "id": 123,
      "message": "KEBAKARAN LT. 7...",
      "triggered_by": "Pak Budi",
      "triggered_at": "2026-05-18T14:32:00Z",
      "total_recipients": 50,
      "confirmed_count": 12,
      "status": "active"
    }
  ]
}
```

#### `POST /api/alarms/{id}/cancel/` - Cancel Alarm
**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "alarm_id": 123,
  "status": "cancelled",
  "message": "Alarm berhasil dibatalkan. Notifikasi aman dikirim ke semua user."
}
```

---

### Confirmation

#### `POST /api/confirm/` - Submit Confirmation
**Request:**
```json
{
  "alarm_id": 123,
  "user_id": 456,
  "user_reported_status": "safe"
}
```

**Response (201):**
```json
{
  "id": 789,
  "alarm_id": 123,
  "user_id": 456,
  "user_reported_status": "safe",
  "confirmed_at": "2026-05-18T14:35:22Z",
  "message": "Konfirmasi berhasil dicatat."
}
```

#### `GET /api/alarms/{id}/confirmations/` - Get Confirmations
**Response (200):**
```json
{
  "alarm_id": 123,
  "total_users": 50,
  "confirmed_count": 12,
  "confirmations": [
    {
      "user_id": 456,
      "user_name": "Budi Santoso",
      "user_reported_status": "safe",
      "confirmed_at": "2026-05-18T14:35:22Z"
    }
  ]
}
```

---

## 🔄 Alur Data End-to-End

### 1️⃣ User Registration Flow
```
User buka app mobile
        ↓
Form input: Nama, HP, Lantai, Tipe Disabilitas
        ↓
Firebase SDK generate FCM Token
        ↓
POST /api/auth/register/ → Backend
        ↓
Backend simpan ke DB (admin_status = pending)
        ↓
App simpan user_id & token ke SharedPreferences
        ↓
Response: "Menunggu verifikasi admin"
```

### 2️⃣ Admin Verification
```
Admin login dashboard
        ↓
Tab "Verifikasi User" → lihat daftar pending
        ↓
Admin klik tombol "Verifikasi" atau "Tolak"
        ↓
PATCH /api/users/{id}/status/ → Backend
        ↓
Backend update admin_status = safe
        ↓
User sekarang aktif & bisa terima alarm
```

### 3️⃣ Emergency Alarm Trigger (CORE FLOW)
```
Admin terima laporan (satpam/call center)
        ↓
Dashboard → Tab Alarm
        ↓
Ketik pesan: "KEBAKARAN LT. 7. GUNAKAN TANGGA DARURAT TIMUR."
        ↓
Klik tombol merah "KIRIM ALARM KE SEMUA USER"
        ↓
Backend:
  1. Buat Alarm_Log (status = active)
  2. Query User dengan admin_status IN (safe, evacuating, trapped)
  3. Ambil FCM token masing-masing
  4. Kirim FCM multicast ke semua token
  5. Update total_recipients
        ↓
Firebase kirim ke semua HP user
        ↓
HP User → Fullscreen alert muncul
  - Background MERAH
  - Teks besar (32sp+)
  - Getar SOS [500, 1000, 500, 1000, 500, 1000] × 3
  - Flash merah-putih (via torch)
  - TTS suara (untuk non-deaf)
        ↓
User baca instruksi
```

### 4️⃣ User Confirmation
```
User lihat fullscreen alarm
        ↓
User pilih salah satu tombol:
  [SAYA AMAN] [SAYA TERJEBAK] [SEDANG EVAKUASI]
        ↓
POST /api/confirm/ → Backend
        ↓
Backend buat Confirmation record
        ↓
Dashboard auto-refresh
  Tampilkan: 12 dari 50 user sudah konfirmasi
  Tabel detail per user (hijau = confirmed + status)
```

### 5️⃣ Cancel Alarm
```
Admin klik tombol "BATALKAN ALARM"
        ↓
POST /api/alarms/{id}/cancel/ → Backend
        ↓
Backend kirim FCM baru (type: cancel)
        ↓
HP User terima notifikasi cancel
        ↓
App tampilkan layar HIJAU: "AMAN. KEMBALI BEKERJA."
        ↓
Stop getar + flash + suara
        ↓
Auto-dismiss setelah 5 detik
```

---

## 🗄️ Database Schema

### User Table
```
id              INTEGER     PK Auto increment
name            VARCHAR(100) Nama lengkap user
phone           VARCHAR(20)  Nomor HP (UNIQUE)
floor           INTEGER      Lantai tempat user berada
disability_type VARCHAR(20)  'deaf' / 'blind' / 'none'
fcm_token       TEXT         Firebase Cloud Messaging token per device
admin_status    VARCHAR(20)  'pending' / 'safe' / 'evacuating' / 'trapped' / 'outside'
created_at      DATETIME     Timestamp registrasi
updated_at      DATETIME     Timestamp update terakhir
```

### Admin Table
```
id          INTEGER      PK Auto increment
username    VARCHAR(50)  Username login (UNIQUE)
password    VARCHAR(255) Hash password (Django default)
created_at  DATETIME     Timestamp pembuatan akun
```

### Alarm_Log Table
```
id               INTEGER     PK Auto increment
message          TEXT        Pesan alarm yang diketik admin
triggered_by     INTEGER     FK Admin ID
triggered_at     DATETIME    Waktu alarm dikirim
total_recipients INTEGER     Jumlah user yang menerima notifikasi
status           VARCHAR(20) 'active' / 'cancelled'
```

### Confirmation Table
```
id                   INTEGER     PK Auto increment
user_id              INTEGER     FK User ID
alarm_id             INTEGER     FK Alarm_Log ID
user_reported_status VARCHAR(20) 'safe' / 'trapped' / 'evacuating'
confirmed_at         DATETIME    Waktu konfirmasi
```

---

## 🎨 Dashboard Admin

### Halaman-Halaman

#### 1. **Login Page**
- Username & Password form
- Error handling
- Redirect ke dashboard setelah sukses

#### 2. **Dashboard Ringkasan (Index)**
- Statistik jumlah user (total, pending, aktif)
- Status alarm aktif (jumlah, penerima, konfirmasi)
- Live clock
- Quick action buttons

#### 3. **Tab Verifikasi User**
Menampilkan tabel user dengan `admin_status = pending`:
- Kolom: Nama, No HP, Lantai, Tipe Disabilitas, Waktu Registrasi
- Aksi: Tombol Verifikasi (hijau) & Tolak (merah)
- Saat verifikasi → Status berubah jadi 'safe'

#### 4. **Tab Daftar User**
Menampilkan tabel semua user terverifikasi:
- Kolom: Nama, No HP (clickable → tel:), Lantai, Tipe Disabilitas, Admin Status
- Status dropdown editable (safe/evacuating/trapped/outside)
- Kolom Konfirmasi Terakhir
- AJAX update without page reload

#### 5. **Tab Alarm & Riwayat**
**Bagian Atas - Kirim Alarm:**
- Textarea input (placeholder: "Ketik instruksi evakuasi...")
- Tombol merah besar: "KIRIM ALARM KE SEMUA USER"
- Tombol disabled jika textarea kosong

**Bagian Bawah - Riwayat Alarm:**
| Waktu | Pesan | Admin | Total | Konfirmasi | Status | Aksi |
- Klik baris → expand detail daftar user
  - Hijau = sudah konfirmasi + status laporan
  - Kuning = belum konfirmasi
  - Tampilkan perbandingan: Admin Status vs User Status

---

## 📱 Aplikasi Mobile

### Screens

#### 1. **Registration Screen** (sekali seumur hidup)
- Input fields: Nama, No HP, Lantai (number picker), Tipe Disabilitas (radio)
- Tombol Daftar
- Sukses → simpan user_id & fcm_token ke SharedPreferences
- App tidak perlu login ulang

#### 2. **Home/Standby Screen**
- Menampilkan: "SafeAlert Aktif"
- Informasi user: Nama, Lantai, Status Verifikasi
- Tombol darurat:
  - Hubungi 113 (Pemadam) → `url_launcher: tel:113`
  - Hubungi 110 (Polisi) → `url_launcher: tel:110`
- App siap di background menerima FCM

#### 3. **Fullscreen Alarm Screen** (Emergency Alert)
**Trigger:** Notifikasi FCM dengan `type: emergency` masuk

**Layout:**
- Background MERAH solid (high contrast)
- Teks putih BESAR (32sp+)
- Isi teks = pesan alarm dari admin
- Tombol konfirmasi 3 pilihan:
  ```
  [SAYA AMAN] [SAYA TERJEBAK] [SEDANG EVAKUASI]
  ```

**Hardware Triggers (sesuai disability_type):**
- **Tunarungu:** Getar + Flash + Teks besar (NO suara)
- **Tunanetra:** TTS suara + Getar (NO flash)
- **Non-disabilitas:** Semua (Getar + Flash + TTS + Teks)

**Getar Pattern:**
```
SOS pattern: [500ms, 1000ms, 500ms, 1000ms, 500ms, 1000ms]
Repeat: 3 kali
```

**Flash (torch):**
- Merah-putih blink cepat
- Via `torch_light` plugin

**TTS:**
- Baca pesan alarm
- Via `flutter_tts` plugin

#### 4. **Cancel Screen** (All Clear)
**Trigger:** Notifikasi FCM dengan `type: cancel`

- Background HIJAU solid
- Teks: "AMAN. KEMBALI BEKERJA."
- Stop semua getar + flash + suara
- Auto-dismiss 5 detik

---

## 📋 Firebase & Push Notification

### FCM Payload - Emergency Alarm
```json
{
  "to": "<device_fcm_token>",
  "priority": "high",
  "data": {
    "type": "emergency",
    "alarm_id": 123,
    "message": "KEBAKARAN LT. 7. GUNAKAN TANGGA DARURAT TIMUR."
  },
  "notification": {
    "title": "ALARM DARURAT",
    "body": "KEBAKARAN LT. 7. SEGERA EVAKUASI!"
  }
}
```

### FCM Payload - Cancel
```json
{
  "to": "<device_fcm_token>",
  "priority": "high",
  "data": {
    "type": "cancel",
    "alarm_id": 123,
    "message": "AMAN. KEMBALI BEKERJA."
  }
}
```

### Full Screen Intent (Android)
- Layar muncul **even if HP locked/DND**
- Via `flutter_local_notifications` dengan `fullScreenIntent: true`
- Background handler parse FCM payload & trigger fullscreen activity

---

## ✅ Todo & Roadmap

### Phase 1: Setup & Architecture ✅
- [x] Define data models & ERD
- [x] Finalize API specification
- [x] Create GitHub repository structure
- [x] Setup Django project
- [x] Initialize Flutter project

### Phase 2: Backend Foundation 🔄
- [ ] Implement User model & serializers
- [ ] Implement Admin authentication (JWT)
- [ ] Implement Alarm_Log model & FCM service
- [ ] Implement Confirmation model
- [ ] Create all API endpoints
- [ ] Setup Firebase-admin-python integration
- [ ] Write & run API endpoint tests (Postman/pytest)

### Phase 3: Mobile Development 🔄
- [ ] Build Registration screen UI
- [ ] Setup Firebase messaging & background handler
- [ ] Implement fullscreen alarm screen (getar + flash + TTS)
- [ ] Implement personalized alert per disability_type
- [ ] Add confirmation buttons (3 choices)
- [ ] Add emergency call buttons (113, 110)
- [ ] Add standby home screen
- [ ] Build APK debug

### Phase 4: Dashboard Frontend 🔄
- [ ] Create login page UI
- [ ] Create dashboard layout (sidebar + navbar)
- [ ] Build Verifikasi User tab
- [ ] Build Daftar User tab (with AJAX dropdown)
- [ ] Build Alarm & Riwayat tab
- [ ] Implement tel: links for phone numbers
- [ ] Add real-time update with WebSocket or polling

### Phase 5: Integration 🔄
- [ ] Test full flow: Registration → Verification → Alarm → Confirmation
- [ ] Test cancel alarm flow
- [ ] Verify FCM multicast delivery
- [ ] Test personalized alerts on all disability types
- [ ] Fix UI bugs & improve UX

### Phase 6: Polish & Testing 🔄
- [ ] Add form validation (phone unique, floor valid)
- [ ] Improve error handling & user feedback
- [ ] Add loading states & spinner
- [ ] Test permissions (vibrate, flash, notifications)
- [ ] Scenario testing (lihat Bab 9 architecture document)
- [ ] Performance optimization

### Phase 7: Deployment & Demo 🔄
- [ ] Deploy Django backend (Railway/Render)
- [ ] Deploy dashboard (auto with Django)
- [ ] Generate Firebase release APK
- [ ] Create 3-minute demo script
- [ ] Prepare all devices & charge
- [ ] Final code push & tag v1.0-hackathon

### Phase 8: Future Enhancement 💡
- [ ] GPS auto-detection per floor (untuk production)
- [ ] Token cleanup mechanism (handle dead tokens)
- [ ] SMS fallback (Twilio integration)
- [ ] iOS support (Apple Critical Alert permission)
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Audio beacon system
- [ ] Two-way SOS communication

---

## 🚨 Batasan yang Diketahui

| Batasan | Penyebab | Workaround |
|---------|---------|-----------|
| Token permanen | Uninstall app = token zombie | Cleanup nanti di production |
| Lantai manual | Tidak ada deteksi otomatis | Validasi form UI saja |
| Android only | iOS critical alert butuh Apple permission | iOS untuk fase 2 |
| SQLite di dev | Setup PostgreSQL memakan waktu | Migrate nanti ke PostgreSQL |
| No internet fallback | HP tanpa internet = no notif | SMS fallback (nice-to-have) |
| Battery optimization | GPS terus-menerus drain | GPS hanya saat evakuasi aktif |

---

## 📞 Tim & Pembagian Kerja

| Role | Tugas | Stack |
|------|-------|-------|
| **Dev 1 (Mobile)** | Flutter app, hardware native, FCM setup | Dart, Flutter, Firebase SDK |
| **Dev 2 (Backend)** | Django, DRF, DB, FCM integration | Python, Django, PostgreSQL, pyfcm |
| **Dev 3 (Dashboard)** | Web admin UI, operator console | Django Templates, Bootstrap 5 |

---

## 📚 Dokumen Referensi

- `DOKUMEN_ARSITEKTUR_SAFEALERT.txt` - Full technical specification (20 pages)
- `README.md` - Quick start guide
- `SAFEALERT_AGENT_PROMPT_v2.md` - AI agent system prompt
- `implementation_plan.md.resolved` - Frontend polish plan

---

**Versi:** 1.0  
**Tanggal:** 20 Mei 2026  
**Event:** Astra Hackathon 24 Jam  
**Repository:** https://github.com/AvilioWatson/Simulasi_Hackathon_Astra

