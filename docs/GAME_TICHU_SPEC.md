# GAME_TICHU_SPEC (Full 단판+타이브레이커, LOCKED v3)

이 스펙은 **기본 1라운드**로 승패를 결정하되, **동점이면 1라운드를 추가(총 2라운드 최대)**로 진행하고  
**전(前) 라운드 점수 + 추가 라운드 점수 합산**으로 승패를 결정합니다.

진행 방향: **반시계**  
폭탄 인터럽트: **없음(내 턴에만 사용 가능)**

---

## 1) 인원/팀/좌석
- 4인 고정, 2v2
- 좌석: 0-1-2-3
- 팀: (0 & 2) vs (1 & 3)
- 진행 방향: 반시계 (다음 플레이어 = (현재좌석 - 1) mod 4)

---

## 2) 카드 구성(56장)
- 일반 52장 + 특수 4장: MAHJONG, PHOENIX, DRAGON, DOG

랭크 순서: 2 < 3 < ... < 10 < J < Q < K < A  
(MAHJONG은 싱글에서 1로 취급)

---

## 3) 점수 카드(LOCKED)
- 5 = +5
- 10 = +10
- K = +10
- DRAGON = +25
- PHOENIX = -25
- 그 외 0

---

## 4) 승패/동점 타이브레이커(LOCKED)
### 4.1 기본 라운드 종료 후
- 팀 총점이 높은 팀 승
- **동점이면** 추가 라운드 1번 진행

### 4.2 추가 라운드(타이브레이커) 후
- **(1라운드 점수 + 추가 라운드 점수) 합산**이 높은 팀 승
- 합산도 동점이면: **추가 라운드의 1등(첫 아웃) 플레이어를 배출한 팀 승**

> 결과적으로 매치는 1라운드 또는 2라운드로 끝난다.

---

## 5) 게임 페이즈(상태기계)
라운드별로 동일한 페이즈를 수행하며, match 레벨에서 누적 점수를 가진다.

1. `TICHU.DEAL_PART1` : 각 플레이어에게 8장 딜
2. `TICHU.DECLARE_GRAND_WINDOW` : 그랜드티츄 선언 창(8장만 본 상태)
3. `TICHU.DEAL_PART2` : 나머지 6장 딜(총 14장)
4. `TICHU.EXCHANGE_SELECT` : 각자 3장 선택(LEFT/PARTNER/RIGHT)
5. `TICHU.EXCHANGE_COMMIT` : 교환 적용
6. `TICHU.TRICK_PLAY` : 트릭 진행(티츄 선언: 각자 “첫 카드 내기 전”까지)
7. (조건부) `TICHU.DRAGON_DONATE` : 드래곤으로 트릭 승리 시, 기부 대상 선택
8. `TICHU.ROUND_END` : 1명만 남으면 종료/꼴찌 처리 및 점수 계산
9. `TICHU.NEXT_ROUND_OR_END` : 동점이면 1회 추가 라운드, 아니면 종료
10. `TICHU.GAME_END`

---

## 6) 선언 시스템
### 6.1 그랜드 티츄(Grand Tichu)
- 선언 시점: `TICHU.DECLARE_GRAND_WINDOW`
- 점수: 성공 +200 / 실패 -200
- 성공 조건: 선언한 플레이어가 **그 라운드 1등으로 아웃**
- 액션: `TICHU.DECLARE_GRAND_TICHU`

### 6.2 티츄(Tichu)
- 선언 시점: `TICHU.TRICK_PLAY` 중, 해당 플레이어가 **첫 카드 내기 전**
- 점수: 성공 +100 / 실패 -100
- 성공 조건: 선언한 플레이어가 **그 라운드 1등으로 아웃**
- 액션: `TICHU.DECLARE_TICHU`

제약:
- 한 플레이어는 Tichu 또는 Grand Tichu 중 하나만 선언 가능(중복 불가)

---

## 7) 시작 플레이어
- `MAHJONG` 을 가진 플레이어가 첫 리드

---

## 8) 조합(Combo) 정의 및 비교 규칙
- 현재 테이블의 최상단 콤보를 이길 수 있는 “같은 타입”의 더 강한 콤보만 낼 수 있음
- **폭탄은 예외로 타입 제한 없이 낼 수 있지만, 내 턴에만 가능**

### 8.1 콤보 타입
- SINGLE / PAIR / TRIPLE / FULL_HOUSE
- STRAIGHT (len>=5)
- PAIR_STRAIGHT (연속 페어, len>=2페어)
- BOMB4 (4-of-a-kind)
- BOMB_STRAIGHT_FLUSH (같은 무늬 STRAIGHT, len>=5)

### 8.2 비교 규칙(요약)
- SINGLE/PAIR/TRIPLE/FULL_HOUSE: 핵심 랭크 비교
- STRAIGHT/PAIR_STRAIGHT: 길이 동일 + highRank 비교
- BOMB:
  - BOMB_STRAIGHT_FLUSH > 어떤 BOMB4
  - 스트레이트플러시끼리: (len 큰 것) > (len 같으면 highRank) > (완전 동점이면 suit)
  - BOMB4끼리: 랭크 큰 것
- suit 우선순위(타이브레이커): ♠ > ♥ > ♦ > ♣

---

## 9) 특수 카드 룰(LOCKED)
### 9.1 DOG
- 리드로만 가능
- 내면 다음 턴은 파트너가 리드(방향 무시)

### 9.2 DRAGON
- SINGLE 최강(피닉스도 드래곤은 못 이김)
- 드래곤으로 트릭을 이겨 트릭이 종료되면, 그 트릭을 **상대 중 1명에게 기부**
  - 페이즈: `TICHU.DRAGON_DONATE`
  - 액션: `TICHU.DRAGON_DONATE` { toOpponentPlayerId }

### 9.3 PHOENIX (와일드 포함)
- SINGLE:
  - 리드: 1.5
  - 추종: 직전 싱글 +0.5
- 콤보 와일드: PAIR/TRIPLE/FULL_HOUSE/STRAIGHT/PAIR_STRAIGHT에 포함 가능
- 제약:
  - **폭탄에는 사용 불가**
  - DRAGON을 이길 수 없음
- Phoenix 포함 콤보는 `declaredCombo`로 “Phoenix 대체 랭크” 명시(모호성 제거)

### 9.4 MAHJONG + WISH(소원)
- MAHJONG은 SINGLE에서 1, STRAIGHT에 포함 가능
- MAHJONG을 리드로 낼 때, 플레이어는 `wishRank`를 선택:
  - 2..A 중 하나 **또는 선택 안함(NONE)**
- Wish 강제 규칙:
  - wishRank가 NONE이면 wish는 활성화되지 않음(강제 없음)
  - wishRank가 설정되어 있고, 내 차례에 **wishRank 포함 합법 행동**이 존재하면 → 그 행동들만 선택 가능
  - wishRank 포함 판정에는 Phoenix가 wishRank로 선언된 경우도 포함
- wish는 wishRank가 포함된 카드/콤보가 한 번이라도 성공적으로 플레이되면 즉시 해제

---

## 10) 폭탄 규칙(인터럽트 없음, LOCKED)
- 폭탄은 **내 턴에만** 제출 가능
- 현재 최상단 콤보가 무엇이든(비폭탄/폭탄) 폭탄을 낼 수 있고,
  - 비폭탄 위에는 어떤 폭탄도 가능
  - 폭탄 위에는 더 강한 폭탄만 가능
- 폭탄을 내면 최상단 콤보가 폭탄으로 교체되고, 이후는 일반 턴 진행(반시계)

---

## 11) 교환(Exchange)
- LEFT/PARTNER/RIGHT에 1장씩 선택(총 3장)
- 모두 확정되면 동시에 적용
- 액션: `TICHU.SELECT_EXCHANGE`, `TICHU.CONFIRM_EXCHANGE`

---

## 12) 트릭 종료/라운드 종료(LOCKED)
### 트릭
- 낼 수 없으면 PASS
- 3명 연속 PASS 하면 트릭 종료 → 마지막 낸 플레이어가 트릭 획득 + 다음 리드

### 라운드 종료(꼴찌 처리)
- **딱 1명만 손패가 남았을 때** 라운드 종료
- 꼴찌(마지막 남은 플레이어):
  1) 남은 손패를 상대 팀에게 제공
  2) 자신이 획득한 트릭 더미를 1등(첫 아웃)에게 제공

### 더블 승리
- 같은 팀이 1등+2등이면:
  - 승리팀 +200
  - 트릭 점수/꼴찌 처리는 생략
  - 선언 점수는 적용

---

## 13) 라운드 점수 계산(LOCKED)
1) 더블 승리 여부 확인
2) (더블) +200 적용 / (비더블) 트릭 점수 + 꼴찌 처리 반영
3) 선언 점수 반영(Tichu ±100, Grand ±200)
4) 라운드 팀 점수 산출

매치(게임) 점수:
- 기본: 라운드 점수
- 동점 발생 시: 라운드1 + 라운드2 합산

---

## 14) Action 타입(LOCKED)
- `TICHU.DECLARE_GRAND_TICHU`
- `TICHU.DECLARE_TICHU`
- `TICHU.SELECT_EXCHANGE`
- `TICHU.CONFIRM_EXCHANGE`
- `TICHU.PLAY_CARDS` { cards:[...], declaredCombo?:{ type, highRank?, length?, phoenixAs?, wishRank? } }
- `TICHU.PASS`
- `TICHU.PLAY_BOMB` { cards:[...], declaredCombo:{ type:"BOMB4|BOMB_STRAIGHT_FLUSH", highRank, length, suit } }
- `TICHU.DRAGON_DONATE` { toOpponentPlayerId }

---

## 15) Flutter UX 체크리스트(필수)
- Grand 선언 팝업(8장 상태)
- Tichu 선언 버튼(첫 카드 전까지)
- Mahjong 리드 시 wishRank 선택 UI: 2..A + **선택 안함**
- Dragon 트릭 종료 시 “상대 선택” UI
- Phoenix 콤보: Phoenix 대체 랭크 선택/표시
- Tie-breaker: 동점이면 “추가 라운드 시작” UI 및 누적 점수 표시
