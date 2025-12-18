# BOT_SPEC (MVP, LOCKED v3)

## 공정성
- bot은 서버가 제공하는 observation/legalActions만 사용
- 상대 손패/덱/RNG 접근 금지

## 난이도(P0)
- EASY / NORMAL

---

## Las Vegas
- EASY: 큰 돈 우선 + 가능하면 그 카지노로 가는 value, 아니면 가장 많이 나온 value
- NORMAL: 동점 탈락 위험 회피 + 큰 돈 우선 + 경쟁 반영

---

## Tichu (Full 단판 룰)
### EASY
- Declare: 하지 않음
- Play: 가능한 가장 낮게, 아니면 PASS
- Bomb: 기본적으로 사용 안 함(또는 legalActions가 1개뿐일 때만)

### NORMAL
- Grand 선언(8장 기준): 폭탄 보유 또는 고랭크(10~A) 비중이 높을 때만 선언
- Tichu 선언: 첫 카드 전, 손이 매우 강할 때만
- Wish: wishRank="NONE"이면 강제 없음. wish가 활성화되면 legalActions 제한을 그대로 따름
- Bomb:
  - 내 턴에만 사용 가능(인터럽트 없음). 큰 점수 트릭을 차단하거나, 상대 Tichu 성공을 막을 때 우선 고려
- Dragon 기부:
  - 점수(10/K/Dragon) 카드가 이미 상대 트릭 더미에 많이 쌓인 쪽을 피해서 기부


### 타이브레이커 라운드
- 추가 라운드(라운드2)에서는 이전 라운드 결과는 참고하지 않고, 현재 라운드를 이기도록 플레이(서버가 누적점수는 별도 관리)
