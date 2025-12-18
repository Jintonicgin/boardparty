# TEST_PLAN (LOCKED v3)

## 목표
- 게임 완주 + 재접속 복구 + 결정적 재현
- Tichu Full 룰(Declare/Wish/Bomb(인터럽트 없음)/Dragon donate) 핵심 케이스 포함

## 단위 테스트
### Las Vegas
- 동점 제거, 정산, choose_value 검증

### Tichu
- 콤보 판정: SINGLE/PAIR/TRIPLE/FULL_HOUSE/STRAIGHT/PAIR_STRAIGHT
- Phoenix 와일드: declaredCombo 기반 대체 랭크 검증
- Bomb:
  - BOMB4 비교
  - BOMB_STRAIGHT_FLUSH 비교(길이/하이랭크/슈트 타이브레이커)
- Mahjong Wish:
  - wish 활성화/해제
  - wishRank="NONE" 선택 시 강제 없음
  - wish 가능한데 다른 플레이 제출 → ILLEGAL_ACTION
- Dragon donate:
  - donate phase 진입/종료 + 점수 더미 이동
- Declare:
  - Grand window(8장)에서만 가능
  - Tichu: 첫 카드 내기 전까지만 가능
  - 성공/실패 점수 반영
- 단판 종료:
  - 1명 남으면 종료 + 꼴찌 처리
  - 더블 승리 +200(선언 점수 포함)

## 통합 테스트
- seed 고정 + action sequence 재생 → 결과 동일
- 재접속: 트릭 도중 끊김/복귀 후 상태 동일(legalActions 포함)

## E2E(추천)
- Las Vegas: 500판 bot self-play 오류 0
- Tichu: 200판 bot self-play 오류 0
