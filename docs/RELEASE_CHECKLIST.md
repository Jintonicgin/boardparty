# RELEASE_CHECKLIST (Flutter)

## Android
- `flutter build appbundle`
- Play Console Internal Testing 업로드
- 크래시/ANR 확인

## iOS (Mac)
- `flutter build ipa` 또는 Xcode Archive
- TestFlight 업로드
- 서명/프로비저닝/번들ID 확인

## Web Release Checklist
- Chrome / Edge / Safari 최신 2버전 정상 플레이
- Pointer / Mouse 입력 정상 동작
- Resize / Fullscreen 전환 시 상태 유지
- Background 탭 전환 후 복귀 시 reconnect 정상
- 모바일 Safari(iOS)에서 Web 플레이 가능 여부 확인

## Server
- 환경변수/시크릿 설정
- DB 마이그레이션 적용
- 로그/모니터링 확인
