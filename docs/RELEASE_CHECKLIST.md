# RELEASE_CHECKLIST (Flutter)

## Android
- `flutter build appbundle`
- Play Console Internal Testing 업로드
- 크래시/ANR 확인

## iOS (Mac)
- `flutter build ipa` 또는 Xcode Archive
- TestFlight 업로드
- 서명/프로비저닝/번들ID 확인

## Server
- 환경변수/시크릿 설정
- DB 마이그레이션 적용
- 로그/모니터링 확인
