# SafeAlert

**Sistem Alarm Darurat Multisensori Berbasis Kendali Terpusat**

SafeAlert adalah platform manajemen evakuasi darurat yang dirancang khusus untuk memfasilitasi peringatan cepat dan tepat sasaran, termasuk penyesuaian (personalized alert) bagi pengguna penyandang disabilitas (tunarungu, tunanetra) di dalam gedung. 

Repositori ini memuat kode untuk **Backend (Django REST Framework)** dan **Dashboard Admin Web (Django Templates + Bootstrap 5)**.

---

## 🚀 Fitur Utama

- **Dashboard Operator (Web)**: Mengelola pendaftaran user, verifikasi, dan memantau status evakuasi secara live.
- **Multicast Alarm Darurat**: Mengirim pesan Firebase Cloud Messaging (FCM) sekaligus ke seluruh device user yang aktif di dalam gedung.
- **Manajemen Konfirmasi Laporan**: Mencocokkan status aman/terjebak dari sistem melawan konfirmasi langsung dari pengguna.
- **RESTful API Endpoint**: Tersedia untuk integrasi aplikasi mobile (Flutter) dengan kapabilitas otentikasi JWT.

---

## 🛠️ Persyaratan Sistem (Prerequisites)

Pastikan sistem Anda telah menginstal:
- **Python 3.9+**
- **pip** (Python package manager)
- **Git**

---

## ⚙️ Panduan Instalasi dan Menjalankan Proyek

Ikuti langkah-langkah di bawah ini untuk menjalankan backend dan dashboard secara lokal:

### 1. Navigasi ke Direktori Backend
Buka terminal/Command Prompt, lalu masuk ke direktori backend:
```bash
cd safealert_backend
```

### 2. Buat dan Aktifkan Virtual Environment (Venv)
Sangat disarankan menggunakan virtual environment agar dependensi tidak bentrok.
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

### 3. Instal Dependensi
Jalankan perintah berikut untuk menginstal semua library yang diperlukan:
```bash
pip install -r requirements.txt
```

### 4. Setup Kredensial Firebase (Opsional untuk testing lokal)
Untuk fitur push notification, pastikan Anda memiliki file `firebase-credentials.json` (Service Account Key dari Firebase Console) dan meletakkannya di root direktori `safealert_backend`. Jika Anda hanya mengetes UI, ini bisa diabaikan atau akan menampilkan peringatan FCM.

### 5. Inisialisasi & Seeding Database (Penting!)
Kami telah menyiapkan skrip khusus untuk men-generate data uji (mock data) sehingga dashboard langsung terisi dengan data yang realistis tanpa perlu registrasi manual. 

Jalankan perintah ini:
```bash
python seed_mock_data.py
```
*Skrip ini akan menghapus data lama dan membuat:*
- Akun Admin Dashboard
- 5 User Aktif (dengan status aman, terjebak, dsb.)
- 3 User Pending (menunggu verifikasi)
- Riwayat Alarm dan konfirmasi simulasi.

### 6. Jalankan Development Server
Mulai server Django dengan:
```bash
python manage.py runserver
```

---

## 💻 Mengakses Dashboard Admin

Setelah server berjalan, Anda dapat membuka dashboard web melalui browser:

- **URL Dashboard**: [http://127.0.0.1:8000/dashboard/](http://127.0.0.1:8000/dashboard/)
- **Username**: `admin_gedung`
- **Password**: `password123`

### Halaman yang Tersedia:
- **Ringkasan**: Gambaran statistik user dan status alarm aktif.
- **Verifikasi User**: Menyetujui user baru yang mendaftar via aplikasi mobile.
- **Daftar User**: Memantau seluruh user aktif, mengganti status evakuasi, dan fitur klik-untuk-telepon (call).
- **Alarm & Riwayat**: Konsol untuk mengirim perintah evakuasi darurat dan melihat laporan sinkronisasi keselamatan tiap user.

---

## 📡 API Endpoints (Untuk Developer Mobile)

Backend SafeAlert menggunakan `http://127.0.0.1:8000` sebagai *Base URL* selama development. Berikut adalah beberapa endpoint utamanya:

- `POST /api/auth/register/` - Pendaftaran user mobile.
- `POST /api/auth/login/` - Mendapatkan JWT token admin.
- `POST /api/confirm/` - User mengirimkan konfirmasi saat evakuasi.
- `POST /api/alarms/trigger/` - (Admin Only) Memicu alarm darurat.

*(Untuk struktur request & response yang lengkap, silakan merujuk pada `DOKUMEN_ARSITEKTUR_SAFEALERT.txt` di root repository).*

---
*Dibangun untuk Astra Hackathon 24 Jam.*
