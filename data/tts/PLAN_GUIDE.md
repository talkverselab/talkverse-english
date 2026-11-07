# 회화 음성 감정 계획 작성법 (영어)

편마다 `data/tts/plan/<편id>.json` 한 파일. **계획은 `tools/tts/make_plan.py` 가 회화의 `emotion`·`segs` 로 만든다 — 손으로 쓰지 않는다.** 아래는 그 형식과 감정 고르는 기준이다. 검사 `python3 tools/tts/check_plan.py <편id>...`. 일본어앱 `data/tts/PLAN_GUIDE.md` 와 같은 틀, 칸 이름만 다르다.

```json
{"ep":"r1_x_a1",
 "cast":{"B":"ayu","C":"man_m"},
 "turns":{
  "1":{"segs":[["cheerful","Hey, {name}!"]]},
  "2":{"segs":[["surprised","Wait, for real?"],["gentle","Okay, let's go."]]}
 }}
```

- **segs** = 턴을 말하는 순서대로 나눈 조각 `[감정, 본문]` 또는 `[감정, 본문, 읽기]`. 이어 붙이면 그 턴의 `en` 과 같아야 한다(대소문자·공백·문장부호·괄호 지문은 검사에서 무시).
- **읽기(세 번째 칸)** = 음성 모델이 읽을 글. 숫자는 글자로(`30` → `thirty`), 지문·이모지·`lol` 는 뺀다. 두 글자 미만 조각은 만들지 않는다.
- **감정은 문장마다 대사 맥락으로 정한다.** 감정이 바뀌는 곳에서만 나눈다. neutral 만 쓰지 말 것 — 점원·안내는 polite, 받아치기는 tsukkomi, 심쿵 턴은 gentle·shy.
  감정: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle.
- **cast**: A(학습자)는 쓰지 않는다(자동 am/af). 고정 인물 Maya=maya · Emma=emma · Jake=jake · Daniel=daniel. 그 밖은 나이·성별로 man_y/man_m/man_o/woman_y/woman_m/woman_o/kid · 안내 방송=announce · 키오스크=robot.
- **자리 표시**: `{name}`·`{country}`·`{city}` 은 그대로 둔다(자동: 남성판 Alex, 여성판 Sara — 고정 인물 Emma 와 겹치지 않게 · Brazil · Sao Paulo, 한국어 뜻의 조사는 받침에 맞춰 바뀐다). 그 밖의 자리는 `fill` 에 `{text, rd, ko}` 로.
- **남성판·여성판(`m`·`f`)**: 영어는 문법 성별이 없어 거의 필요 없다. 학습자 성별이 말에 드러나는 턴만 그 판의 전체 턴(`text`·`rd`·`ko`·`segs`)을 넣는다.
