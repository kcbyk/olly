# Olly — Social App

Flutter sosyal uygulama projesi.

## 🏗️ Mimari

**Clean Architecture + Feature-First** klasör yapısı:

```
lib/
├── core/              # Paylaşılan altyapı
│   ├── constants/     # AppColors, AppSizes
│   ├── errors/        # Failure union types (Freezed)
│   ├── extensions/    # Context, String, DateTime ext
│   ├── router/        # go_router konfigürasyonu
│   ├── theme/         # Material 3 tema
│   └── widgets/       # OllyAvatar, OllyButton, MainShell (Pill Bar)
│
└── features/
    ├── auth/          # Login, Register
    ├── friends/       # Arkadaş listesi, arkadaş ekleme
    ├── messaging/     # Konuşmalar, sohbet
    ├── voice_rooms/   # Ses odaları listesi, oda ekranı
    └── profile/       # Profil, profil düzenleme
```

## 🚀 Başlarken

### 1. Bağımlılıkları yükle
```bash
flutter pub get
```

### 2. Kod üretimi çalıştır (Freezed + Riverpod)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Firebase kurulumu
- [Firebase Console](https://console.firebase.google.com) üzerinden yeni proje oluştur
- FlutterFire CLI ile yapılandır:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. LiveKit kurulumu
- [LiveKit Cloud](https://livekit.io) veya self-host server kur
- `.env` dosyasını düzenle:
```env
LIVEKIT_URL=wss://your-server.livekit.cloud
LIVEKIT_API_KEY=your_key
LIVEKIT_API_SECRET=your_secret
```

### 5. Uygulamayı çalıştır
```bash
flutter run
```

## 📦 Tech Stack

| Katman | Teknoloji |
|---|---|
| State Management | Riverpod 2.x |
| Navigation | go_router |
| Models | Freezed + json_serializable |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Voice Rooms | LiveKit Flutter SDK |
| Local DB | Drift (SQLite) |
| UI Animations | flutter_animate |

## 🎨 Floating Pill Bar

- **Frosted glass** efekti (BackdropFilter + blur)
- **Scroll-aware**: aşağı scroll'da gizlenir
- **Haptic feedback** her tab geçişinde
- **Animated label**: aktif tab genişler, etiket görünür
- **RepaintBoundary**: performans izolasyonu

## 📁 Feature Yapısı (Her Feature)

```
feature/
├── data/
│   ├── datasources/   # Firebase / HTTP / Local veri kaynakları
│   ├── models/        # DTO'lar (Freezed + json_annotation)
│   └── repositories/  # Repository implementasyonları
├── domain/
│   ├── entities/      # Saf Dart modeller (Flutter bağımlılığı yok)
│   ├── repositories/  # Abstract interface'ler
│   └── usecases/      # İş kuralları
└── presentation/
    ├── controllers/   # Riverpod AsyncNotifier'lar
    ├── pages/         # Sayfa widget'ları
    └── widgets/       # Feature-specific widget'lar
```
