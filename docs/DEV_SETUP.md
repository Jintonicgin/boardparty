# DEV_SETUP (Flutter + Node/TS, Windows & Mac)

## 공통
- Git
- Docker Desktop
- Node.js 20 LTS
- pnpm
- Flutter SDK (권장: FVM 사용)

---

## 서버 로컬 실행
```bash
docker compose up -d
cd apps/server
pnpm install
pnpm dev
```

---

## Flutter 앱 실행
### 1) 의존성
```bash
cd apps/mobile
flutter pub get
```

### 2) Android (Windows/갤럭시북)
- Android Studio 설치 + Android SDK
- 에뮬레이터 또는 실기기(USB 디버깅)

실행:
```bash
flutter run
```

### 3) iOS (Mac/Xcode)
- Xcode 설치
- CocoaPods 설치(필요 시):
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

실행:
```bash
flutter run -d ios
```

Xcode로 열기(동료가 이미 Xcode 사용 중인 경우):
- `apps/mobile/ios/Runner.xcworkspace` 를 Xcode로 열기
- Signing/Team 설정 후 Run

---

## 환경변수
- 서버: `.env` (루트 `.env.example` 참고)
- 앱: 개발 편의상 `assets/config.json` 또는 `--dart-define` 중 하나로 고정 권장(선택)
