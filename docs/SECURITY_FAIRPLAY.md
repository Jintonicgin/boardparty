# SECURITY & FAIRPLAY (LOCKED v3)

## 서버 권위
- 셔플/RNG/판정은 서버만 수행
- 클라는 action 요청만, 결과는 event/state로 수신

## 검증
- JSON Schema 검증
- room/match 소속 검증
- 턴 규칙: turnPlayerId만 action 가능
- 룰 검증: wish 강제, dragon donate, declare window 등
- 실패 시 ILLEGAL_ACTION

## 재접속
- 유예 90초
- 재연결 후 auth:hello → room:state + match:state push

- Tichu 폭탄은 인터럽트 없음: turnPlayerId가 아닌 사용자의 폭탄 제출은 거부
