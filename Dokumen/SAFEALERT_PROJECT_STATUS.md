# SafeAlert - Project Overview & Status

**Generated:** 20 Mei 2026 22:12 UTC+7  
**Project:** Simulasi Hackathon Astra  
**Duration:** 24 Jam  

---

## 🎯 Project Summary

**SafeAlert** adalah sistem alarm darurat multisensori yang dirancang untuk memberikan peringatan evakuasi yang **inklusif dan tepat sasaran** kepada penyandang disabilitas di dalam gedung.

### Komponen Utama
1. **Backend Django REST API** - Manajemen user, alarm, dan notifikasi
2. **Mobile App (Flutter)** - Receiver alert dengan personalized notifications
3. **Dashboard Admin (Web)** - Operator console untuk trigger & monitor alarms
4. **Firebase Cloud Messaging** - Push notification hub

---

## 📊 Project Status Dashboard

### Overall Progress
```
████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 0% Complete
Total Todos: 60 | Pending: 60 | In Progress: 0 | Done: 0
```

### Phase Breakdown

| Phase | Component | Todos | Status | Priority |
|-------|-----------|-------|--------|----------|
| **Phase 2** | Backend Foundation | 12 | ⏳ Pending | 🔴 CRITICAL |
| **Phase 3** | Mobile App | 15 | ⏳ Pending | 🔴 CRITICAL |
| **Phase 4** | Dashboard Admin | 12 | ⏳ Pending | 🟡 HIGH |
| **Phase 5-7** | Integration & Deploy | 11 | ⏳ Pending | 🟡 HIGH |
| **Phase 8+** | Future Enhancements | 10 | 💡 Planning | 🟢 LOW |

---

## 🏗️ Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                    SAFEALERT SYSTEM                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────┐  │
│  │  Mobile App  │      │   Dashboard  │      │ Firebase │  │
│  │   (Flutter)  │◄────►│  Admin (Web) │◄────►│   FCM    │  │
│  │              │      │              │      │          │  │
│  │ • Register   │      │ • Verify     │      │ • Notify │  │
│  │ • Receive    │      │ • Trigger    │      │ • Route  │  │
│  │ • Alert      │      │ • Monitor    │      │ • Track  │  │
│  │ • Confirm    │      │              │      │          │  │
│  └──────────────┘      └──────────────┘      └──────────┘  │
│         ▲                                            ▲       │
│         │                      ▼                     │       │
│         └────────────────────────────────────────────┘       │
│                                                               │
│              Backend Django REST API                         │
│         (Models, Serializers, Views, URLs)                  │
│                                                               │
│         Database (SQLite Dev / PostgreSQL Prod)             │
│         • User Model (name, phone, floor, disability_type)   │
│         • Admin Model (username, password)                   │
│         • Alarm_Log Model (message, triggered_by, status)    │
│         • Confirmation Model (user_id, alarm_id, status)     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 End-to-End Flow

### 1. User Registration
```
User Opens App
     ↓
Enter: Name, Phone, Floor, Disability Type
     ↓
App generates FCM token
     ↓
POST /api/auth/register/ → Backend
     ↓
Backend saves to DB (admin_status = pending)
     ↓
Response: "Menunggu verifikasi admin"
     ↓
User waits for admin verification
```

### 2. Admin Verification
```
Admin logs into dashboard
     ↓
Tab "Verifikasi User"
     ↓
Admin clicks "Verifikasi" button
     ↓
PATCH /api/users/{id}/status/ (status=safe)
     ↓
User now active and can receive alarms
```

### 3. Emergency Alarm (CORE)
```
Admin receives emergency report
     ↓
Dashboard → Type alarm message
     ↓
Click "KIRIM ALARM KE SEMUA USER"
     ↓
Backend:
• Creates Alarm_Log entry
• Queries all active users
• Sends FCM multicast to all tokens
     ↓
Firebase routes to all devices
     ↓
Mobile receives → Fullscreen alert appears
     ↓
Alert customized per disability type:
• Deaf: Vibrate + Flash + Text (NO sound)
• Blind: TTS + Vibrate (NO flash)
• Normal: All (Vibrate + Flash + TTS + Text)
     ↓
User confirms status (Safe/Trapped/Evacuating)
     ↓
POST /api/confirm/ → Backend saves
     ↓
Dashboard auto-updates confirmation count
```

### 4. Cancel Alarm
```
Admin clicks "Batalkan Alarm"
     ↓
POST /api/alarms/{id}/cancel/
     ↓
Backend sends FCM cancel payload
     ↓
Mobile receives cancel notification
     ↓
Green "ALL CLEAR" screen appears
     ↓
Auto-dismiss after 5 seconds
```

---

## 🛠️ Teknologi yang Digunakan

### Frontend
| Layer | Tech | Version |
|-------|------|---------|
| Mobile | Flutter | 3.x |
| Mobile UI | Dart, Material Design | Latest |
| Mobile Notifications | firebase_messaging | Latest |
| Mobile Hardware | vibrate, torch_light, flutter_tts | Latest |
| Mobile Storage | SharedPreferences | Built-in |
| Web Dashboard | Django Templates | 4.x |
| Web Styling | Bootstrap | 5.x |
| Web Interactivity | AJAX (JavaScript) | ES6 |

### Backend
| Layer | Tech | Version |
|-------|------|---------|
| Framework | Django | 4.x |
| API | Django REST Framework | 3.14.x |
| Database | SQLite (dev) / PostgreSQL (prod) | Latest |
| Authentication | SimpleJWT | 5.x |
| Push Notification | Firebase-admin-python | Latest |
| HTTP Client | requests | 2.28.x |
| Server | Gunicorn/Uvicorn | Latest |

### Infrastructure
| Component | Provider | Status |
|-----------|----------|--------|
| Backend Host | Railway.app / Render.com | Not deployed |
| Database | PostgreSQL (Railway) | Not deployed |
| Firebase Project | Google Firebase Console | Pending setup |
| GitHub Repository | github.com/AvilioWatson/... | Created |
| Version Control | Git | Using |

---

## 📁 Repository Structure

### Current State
```
Simulasi_Hackathon_Astra/
├── safealert_backend/          ← Dev 2 responsible
│   ├── safealert/              ← Django project config
│   ├── users/                  ← User management app
│   ├── alarms/                 ← Alarm management app
│   ├── confirmations/          ← Confirmation tracking
│   ├── dashboard/              ← Admin web interface
│   ├── manage.py               ← Django CLI
│   ├── requirements.txt        ← Python dependencies
│   ├── seed_mock_data.py       ← Test data seeder
│   └── .env                    ← Environment variables
│
├── safealert_mobile/           ← Dev 1 responsible
│   ├── lib/                    ← Flutter source code
│   ├── android/                ← Android-specific code
│   ├── ios/                    ← iOS-specific code
│   ├── pubspec.yaml            ← Flutter dependencies
│   └── .gitignore              ← Ignore patterns
│
├── README.md                   ← Quick start
├── LICENSE                     ← License (MIT)
├── DOKUMEN_ARSITEKTUR_SAFEALERT.txt ← Full spec (20 pages)
└── .github/                    ← GitHub workflows
```

---

## 👥 Team Allocation

| Role | Developer | Responsibilities | Stack |
|------|-----------|------------------|-------|
| **Backend Lead** | Dev 2 | API design, database, FCM, deployment | Python, Django, PostgreSQL |
| **Mobile Lead** | Dev 1 | Flutter app, personalized alerts, hardware integration | Dart, Flutter, Firebase |
| **Frontend Lead** | Dev 3 | Dashboard UI, admin console, operator experience | HTML, CSS, JavaScript, Django Templates |

### Daily Standup Topics
- What did each dev complete yesterday?
- What are they working on today?
- Any blockers or help needed?
- Integration points between components?
- Demo readiness assessment

---

## 📋 File Locations (Documentation)

All documentation files are stored in the session workspace:
```
C:\Users\Wildan\.copilot\session-state\13d9805b-98e6-47a3-a1c1-0516216e536f\
├── SAFEALERT_DOKUMENTASI_LENGKAP.md (this file)
│   └── Complete technical documentation with architecture, API specs, flows
│
└── SAFEALERT_TODOS_DAN_ROADMAP.md
    └── Detailed todo list organized by phase with acceptance criteria
```

### In Repository
```
Simulasi_Hackathon_Astra/
├── README.md
│   └── Quick start guide for setup
│
├── DOKUMEN_ARSITEKTUR_SAFEALERT.txt
│   └── 20-page official architecture document
│
├── SAFEALERT_AGENT_PROMPT_v2.md
│   └── AI agent system prompt
│
└── implementation_plan.md.resolved
    └── Frontend polish implementation details
```

---

## 🚀 Quick Start Commands

### Backend Setup
```bash
cd safealert_backend
python -m venv .venv
.venv\Scripts\activate                    # Windows
# or source .venv/bin/activate            # Mac/Linux
pip install -r requirements.txt
python seed_mock_data.py
python manage.py runserver
# Dashboard: http://127.0.0.1:8000/dashboard/
# Username: admin_gedung | Password: password123
```

### Mobile Setup
```bash
cd safealert_mobile
flutter pub get
flutter run -d <device_id>
```

### API Testing
```bash
# Test registration
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "phone": "081234567890",
    "floor": 5,
    "disability_type": "deaf",
    "fcm_token": "test_token_123"
  }'
```

---

## ✅ Pre-Demo Checklist

- [ ] All 60 todos reviewed and assigned
- [ ] Phase 2 (Backend) completed and tested
- [ ] Phase 3 (Mobile) completed and APK ready
- [ ] Phase 4 (Dashboard) completed and functional
- [ ] Phase 5-7 (Integration) completed and tested
- [ ] Backend deployed to Railway/Render
- [ ] Firebase project configured and tested
- [ ] Demo script finalized (3 minutes)
- [ ] All devices charged (100%)
- [ ] WiFi backup / Personal hotspot ready
- [ ] GitHub repo updated and tagged v1.0-hackathon
- [ ] Final code review and QA passed

---

## 🎬 Demo Flow (3 Minutes)

1. **Intro (15 sec)** - Show dashboard
2. **Registration (30 sec)** - User registers via mobile app
3. **Verification (30 sec)** - Admin verifies user in dashboard
4. **Alarm Trigger (30 sec)** - Admin types alarm message and sends
5. **Alert Reception (30 sec)** - Show fullscreen alert on mobile (show deaf/blind/normal variants)
6. **Confirmation (20 sec)** - User confirms status
7. **Dashboard Update (10 sec)** - Show confirmation appears in dashboard
8. **Cancel Alarm (10 sec)** - Admin cancels alarm
9. **All Clear (15 sec)** - Show green screen on mobile
10. **Conclusion (5 sec)** - Summary and thanks

---

## 🚨 Known Limitations & Workarounds

| Issue | Impact | Workaround |
|-------|--------|-----------|
| Token expires on app reinstall | Can't receive alerts after uninstall | Feature for Phase 2+ |
| Floor entry is manual | Users might enter wrong floor | Validate in form, use GPS in Phase 2 |
| Android only | iOS users excluded | iOS support in Phase 2 |
| SQLite in dev | Performance limits | Use PostgreSQL in production |
| No internet fallback | Can't reach offline users | SMS fallback in Phase 2 |

---

## 📞 Support & Contact

### Documentation
- **Full Architecture:** `DOKUMEN_ARSITEKTUR_SAFEALERT.txt` (20 pages)
- **Quick Start:** `README.md` in repo
- **Technical Spec:** `SAFEALERT_AGENT_PROMPT_v2.md`
- **This File:** Project overview and status

### Questions?
1. Check `SAFEALERT_DOKUMENTASI_LENGKAP.md` for architecture details
2. Check `SAFEALERT_TODOS_DAN_ROADMAP.md` for implementation details
3. Check repository `README.md` for setup issues
4. Check `DOKUMEN_ARSITEKTUR_SAFEALERT.txt` for requirements

---

## 🎯 Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Todos Completed | 60/60 | 0/60 |
| API Endpoints Working | 9/9 | 0/9 |
| Mobile Features | 100% | 0% |
| Dashboard Features | 100% | 0% |
| Backend Deployed | Yes | No |
| Demo Readiness | Ready | Not Ready |
| Confidence Level | High | - |

---

**Last Updated:** 20 Mei 2026 22:12 UTC+7  
**Next Review:** Before Phase 3 starts  
**Version:** 1.0  

**Good luck with the hackathon! 🚀**

