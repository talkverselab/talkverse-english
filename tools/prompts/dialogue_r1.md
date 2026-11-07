# 회화 초안 규칙 — 편 하나를 쓸 때(영어)

1. 그 장면에서 미국 20대가 실제로 하는 짧은 말을 쓴다. 교과서체·번역투·설명 대사·다짐이나 감사로 끝내기 금지.
2. A = 학습자, `{name}`·`{country}`·`{city}` 만. A 의 국적·성별을 대사로 못 박지 않는다.
3. 구조: 질문 → 대답 + 농담 → 되치기. 끝 줄은 짧은 한 방이나 여운. 입에 남는 한 줄이 편마다 있어야 한다.
4. 편마다 `twist_type` 하나(chaos·slip·reveal·emotion·ignore), 전체 chaos 30% 이상. 웃음 킥과 다른 턴에 심쿵 한 줄(연애 편은 필수, `heart`). 연애 = 썸·플러팅까지, 여성이 먼저 다가가는 편을 더 많이. 수위 iOS 12+.
5. 표현 풀(`data/expressions/top_expressions.csv`) 2개 이상. 메타 표현(say that again 등)은 서바이벌 밖에서 편당 1번.
6. ko = 한국 사람이 실제로 하는 말(직역 금지), 말투는 영어 말투에 맞춘다. note = 그 턴 핵심 하나 `X = 뜻`.
7. **턴마다 음성용 감정을 함께 쓴다**(사용자 지시 2026-11-07). 값 16개 = neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. 대사 맥락으로 정하고 밋밋하게 neutral 만 쓰지 않는다. 한 턴에서 감정이 바뀌면 `emo=surprised+worried` 처럼 이어 쓴다.
8. 출처·작품명·실존 브랜드 없이 전부 자체 작문.

## 초안 글 형식(`data/drafts/*.txt`)
```
=== r1_survival_s1
title: 제목
emoji: 🏪
scene: 장면 한 줄(반전 포함)
where: 장소
goal: 학습 목표
kind: survival|short|long|chat
register: polite|casual|chat|mixed
B: Cashier
twist: 5 chaos
expr: yes | just this
--
B | 영어 | 한국어 | 핵심 | 표시
A@21:03 | …
```
표시(칸 5, 빈칸 구분): `emo=<감정>`(필수, 바뀌면 `+` — 문장 경계로 나뉘고, 다른 곳에서 나눌 땐 영어 칸에 ` / `) · `heart` · `callback=<편id>` · `stamp=😂` · `read=false`. 채팅 시각은 화자 뒤 `@시각`.
