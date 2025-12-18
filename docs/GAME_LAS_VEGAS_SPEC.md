# GAME_LAS_VEGAS_SPEC (MVP, LOCKED)

## 고정값
- 인원: 2~5
- 라운드: 4
- 플레이어당 주사위: 8
- 카지노: 1~6
- 돈 카드: 서버 RNG + seed 기반으로 배치(재현 가능)

## Phase
1) SETUP
2) ROUND_START(r=1..4)
3) PLAYER_TURN
   - 서버: ROLL (남은 주사위 전부 굴림)
   - 플레이어: CHOOSE_VALUE (1..6 중 나온 값만 선택 가능)
   - 서버: ASSIGN (선택값 주사위 모두 해당 카지노에 배치)
   - 남은 주사위가 0이면 다음 플레이어
4) ROUND_END_SCORING
   - 카지노별 배치 개수 집계
   - 동점 그룹은 전원 탈락(그 카지노에서 제외)
   - 남은 플레이어를 배치 수 내림차순으로 정렬
   - 돈 카드(큰 값부터) 지급
5) GAME_END
   - 4라운드 합산 최종 승자

## Action
- CHOOSE_VALUE { value:1..6 }

## Observation
- public: round, turnPlayerId, casinoMoney(public), placements(all), scores
- private: remainingDiceValues(roll 결과)

## Events
- LAS_VEGAS.ROUND_START
- LAS_VEGAS.ROLL { playerId, dice:[...] }
- LAS_VEGAS.CHOOSE_VALUE { playerId, value, assignedCount }
- LAS_VEGAS.SCORE { casino, payouts:[{playerId, amount}] }
- LAS_VEGAS.GAME_END { totals, winner }

## Bot (P0)
- EASY: (1) 가장 큰 돈 카드가 걸린 카지노를 우선, (2) 그 카지노로 갈 수 있는 value가 있으면 선택, 없으면 가장 많이 나온 value 선택
- NORMAL: 현재 배치 경쟁을 반영(동점 위험 회피) + 큰 돈 우선
