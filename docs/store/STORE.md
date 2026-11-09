# 스토어 준비 — 영어 · 토익 · 토익스피킹 · OPIc (2026-11-09)

기준: `~/talkverse/STORE_DIFFERENTIATION.md`(애플 지침 4.3 대비, 사용자 "엄청 중요해") · `~/talkverse/PRICING.md`(사용자 확정 2026-11-09).
**이 네 앱은 한 저장소에서 플레이버로 빌드된다 → 4.3 위험이 가장 크다.** 그래서 앱마다 첫 화면·고유 도구·콘텐츠·스크린샷이 서로 겹치지 않게 한다. 공용 엔진(플래시카드·뿌리 단어·알파벳과 발음)은 스토어 문구와 첫 스크린샷에 내세우지 않는다.

## 0. 출시 순서·지금 상태
- 지금 심사 = 한자앱만. 언어앱은 완성된 것부터 하나씩. 이 네 앱은 **아직 내지 않는다** — Zealot·TestFlight 로만.
- 출시 전 반드시 없앨 것(지침 2.1 — 준비 중 화면·빈 메뉴·임시 콘텐츠 금지):

| 앱 | 남은 막힘 | 위치 |
|---|---|---|
| 영어 | 회화가 앱에 없음(샘플 7편은 리뷰 페이지에만) → 홈 「회화가 곧 들어옵니다」 | `main_screen.dart` 오늘의 학습 |
| 영어 | 「문장 플래시카드」(회화 없음)·「소리 사전」 메뉴가 눌러도 아무것도 안 함 | `main_screen.dart` 복습·탐색 탭 |
| 영어 | 조음 위치 그림 = 임시(출시 전 Grok 그림으로 교체) | `assets/images/ipa/` |
| 토익 | 「RC · LC 는 준비 중」 | `toeic_home.dart` 배우기 |
| 토익 | 비즈니스 회화 18편 음성·장면 컷 없음, 앱 아이콘 외 고유 스크린샷 미작성 | — |
| 토익스피킹 | 말하기 내용 전무(「준비 중」) — 지금은 공용 엔진뿐이라 4.3 반려 확실 | `toeic_home.dart` `_SpeakingLearnTab` |
| OPIc | 위와 같음 | 같은 곳 |
| 네 앱 공통 | 로그인·결제(§11) 미착수, 약관·방침 링크 없음 | — |

## 1. 가격(앱 안) — §11 착수 때 그대로 쓴다
결제 화면은 아직 없다(공통 프롬프터 §11 — 사용자 「착수」 뒤). 착수하면 아래 값으로 만든다. 앱 안에서 사이트 가격은 안내하지 않는다. 최초 출시 빌드는 잠금 없이 무료(사용자 2026-11-09).

| 상품 | 상품 ID(영어 = `en`) | 앱 정가 | 앱 할인가(출시 기념·정기 30%) |
|---|---|---|---|
| 1개월(자동 갱신) | `lang_en_1m` | 5,500 | 3,900 |
| 3개월(자동 갱신) | `lang_en_3m` | 12,900 | 9,000 |
| 1년(자동 갱신) | `lang_en_1y` | 28,500 | 19,900 |
| 평생 이용권(서비스 운영 기간 동안) | `lang_en_life` | 69,900 | 49,000 |
| 종합 1년(전 언어) | `all_1y` | 112,900 | 79,000 |
| 종합 평생 | `all_life` | 469,000 | 329,000(할인 없음) |

- 토익·토익스피킹·OPIc 가격은 사용자 확인 뒤(uk 세션이 알림).
- 결제 화면 필수 문구: 자동 갱신과 해지 방법(스토어 구독 관리), 「평생 이용권(서비스 운영 기간 동안)」, 구매 복원 버튼, 이용약관·개인정보 처리방침 링크.

## 2. 앱별 스토어 문안·고유 도구·숫자·스크린샷

### 2-1. 영어유니버스
- **첫 줄**: 영어는 단어보다 「소리」가 벽이다 — 강세와 이어 말하기를 눈으로 보고, 한국어에 없는 소리(r/l·f/p·th)를 짝으로 비교해 귀를 연다.
- **고유 도구**
  1. 강세 표시: 내용어 굵게·기능어 옅게·이어 말하기 ‿ 를 문장 위에 표시(켬/끔).
  2. 알파벳과 발음: 알파벳 26 + 소리 40(모음 11·이중모음 5·자음 24), 한국인이 어려운 소리 묶음, 모음 위치를 영어·한국어 한 그림에, 헷갈리는 짝(light/right·fan/pan·think/sink) 번갈아 듣기.
  3. 미국·영국·호주 발음 선택.
  4. 뿌리 단어 패밀리: 라틴·그리스 어근 99개, 앞가지·어근·뒷가지 색 분해, 「닮은꼴」 구분.
- **실측 숫자**: 절벽 단어 2,494어(앱 표시 2,000위, R1 189 · R2 318 · R3 825), 어근 99·낱말 494, 소리 40. 회화 편 수·음성 줄 수는 회화가 앱에 들어간 뒤 채운다.
- **스크린샷 순서**: ① 강세 표시가 켜진 회화 줄 ② 알파벳과 발음 — r/l 시트(모음 그림·짝 듣기) ③ 절벽 단어 R1~R4 타일 ④ 뿌리 단어 가족 시트 ⑤ 발음 지역 선택. 홈·프로필로 시작하지 않는다.

### 2-2. 토익유니버스
- **첫 줄**: 토익 문법을 외우지 말고 사무실 회화 8턴으로 익힌다 — 문법 요소는 빨간 밑줄, 끝에 Part 5 빈칸 한 문제.
- **고유 도구**
  1. 비즈니스 회화로 익히는 토익 문법: RC 문법 장마다 1편(명사절·접속사/전치사·관계대명사·시간 전치사·접속부사·to부정사·동명사·분사·수동태·시제·비교/도치 등), 문법 구간 빨간 밑줄·영향받는 낱말 빨간 글자·줄 아래 빨간 문법 메모.
  2. 편 끝 「이 편의 문법」 카드 + Part 5 식 빈칸 4지선다.
  3. 토익 단어 익히기: 명사·동사·형용사·부사·관용표현·기본 빈도어 묶음, 20어 단원 타일, 뜻 고르기 퀴즈, 틀린 단어 복습.
- **실측 숫자**: 토익 단어 1,330어(명사 386 · 동사 231 · 형용사 158 · 부사 53 · 관용표현 112 · 기본 빈도어 390), 비즈니스 회화 18편 · 문법 포인트 18 · 빈칸 문제 18.
- **스크린샷 순서**: ① 빨간 밑줄 회화 화면 ② 「이 편의 문법」+빈칸 문제 ③ 토익 단어 묶음 타일 ④ 뜻 고르기 퀴즈 ⑤ 틀린 단어 복습.

### 2-3. 토익스피킹유니버스 — 내용이 생긴 뒤 작성
- 고유 축(계획): 문항 유형 11개별 답변 틀(사진 묘사·질문 응답·의견 제시 등), 준비·답변 시간 타이머, 녹음 후 내 답변 다시 듣기. **지금은 고유 도구가 없어 낼 수 없다.**

### 2-4. OPIc유니버스 — 내용이 생긴 뒤 작성
- 고유 축(계획): 서베이 주제별 답변 스크립트, 돌발·롤플레이 유형, 등급(IM~AL)별 표현. **지금은 고유 도구가 없어 낼 수 없다.**

## 3. 심사 메모(App Review Notes) — 앱마다 이 문단을 넣는다
영어:
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the English app has its own sound & pronunciation module (26 letters and 40 sounds with Korean-speaker comparisons and minimal pairs such as light/right and fan/pan), its own stress-and-linking display for spoken English, a Latin/Greek word-root family module (99 roots), and a vocabulary list measured from an English conversation corpus (2,494 words in frequency "cliff" bands). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

토익(영어앱과 같은 개발자·같은 언어라 특히 분명히):
> This app is a TOEIC exam-prep app, separate from our general English app because the audience, goal and curriculum are different: it teaches TOEIC Reading grammar through 18 original office-conversation episodes (one per grammar chapter, with the target grammar underlined in red and a Part 5-style question after each episode) and a 1,330-word TOEIC vocabulary course grouped by part of speech. It does not contain the general English app's conversation, pronunciation or accent modules as its main content. Learners preparing for the exam search for TOEIC specifically.
