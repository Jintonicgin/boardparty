# STATE_MACHINE_COMMON (공통 게임 엔진 계약, LOCKED v3)

## Engine 인터페이스(개념)
- initMatch(params) -> state
- getObservation(state, playerId) -> obs  (public/private 분리)
- getLegalActions(state, playerId) -> actions
- applyAction(state, playerId, action) -> { nextState, events[] }
- isTerminal(state) -> bool
- getResult(state) -> result

## 타이머/AFK (LOCKED)
- turnTimeSec = 30
- deadline 초과 시 서버가 autoAction 실행(항상 합법)
- autoAction은 “보수적 선택” 우선(게임을 망치지 않기)

## Turn 소유자 규칙(LOCKED)
- 모든 액션은 `turnPlayerId`만 가능
- (예외 없음)  ← 폭탄 인터럽트 규칙 제거

## Bot 공정성(LOCKED)
- bot은 obs + legalActions만 사용
- 숨겨진 정보 접근 금지
