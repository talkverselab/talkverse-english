# HANDOFF — 영어유니버스 (talkverselab/talkverse-english, M6 `~/talkverse/english`)

_최종 2026-11-04 03:00 KST. 영어앱 세션(원격 제어 이름 "영어앱"). Grab(`~/talkverse/en`)과는 별개 앱._

## 상태 표 (공통 프롬프터 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md` 순서)

| 단계 | 상태 |
|---|---|
| ① 캐릭터 시트 | **사용자 통과 2026-11-03** — `data/review/art/chars_en_v1.jpg`, 특징 `data/review/uxui/CHARACTERS.md` (뉴욕 브루클린: Maya·Emma·Jake·Daniel·학습자 남/여). talkverse.uk 세션이 그림 저장소 `chars/en_sheet.jpg` 로 반영 |
| ② UX/UI 시안 | **사용자 통과 2026-11-03** — 그림 `data/review/uxui/sian_en_01.jpg`(Grok), 글 `sian_en_01.md`(이 세션) + `sian_en_grok_01.md`(Grok). 적용 전 태그 `pre-grok-uxui` |
| ③ 아이패드 빌드 | **완료** — 최신 Android **Zealot 빌드 8** https://apps.talkverse.uk/Eyi4j/243 · iOS **TestFlight 빌드 2611040244**(커밋 `24dcc09` 아이콘 E, 2026-11-04 02:5x) |
| ④ 회화 | **사용자 지시 전까지 금지** — 데이터 없음, 화면은 빈 안내 |

## 만든 것
- 일본어앱 구조 복제(커밋 `4c26aea`): 레일 + 왼쪽 칸 + 오른쪽 칸, 시안 02 리더(`EpisodePlayPane`), 그림 카드, 회화 홈(오늘의 컷·빈 안내), 「나」 성과 데스크(편 완주·핵심 표현만 — 라이트너·커버율은 엔진 생기면), 프로필(이름·성별), 앱 업데이트(GitHub `latest`).
- **강세 표시 도구**(사용자 지시, `lib/widgets/stress_text.dart`): 규칙 기반 — 내용어 굵게·기능어 옅게·자음+모음 이어 말하기 ‿, 리더 하단 「강세」 칩으로 켬/끔(기기에 기억). 스크립트·캡션·버블 목록·카드 뒷면. 낱말 안 강세 음절은 아직(사전 데이터 필요).
- **발음 지역 선택**(사용자 지시): 미국 en-US · 영국 en-GB · 호주 en-AU — 리더 하단 칩·「나 → 발음」. `AccentPrefs`(`lib/services/tts_service.dart`).
- **절벽 단어 R1~R4 화면**(커밋 `aa5473c`, `lib/screens/word_freq_screen.dart`): `assets/data/words/en_words.csv` 2,494어 + 단어 그림, R1~R4·그림 단어만 거르기, 누르면 고른 발음.
- **그림 단어 퀴즈**(커밋 `141cbb2`, `lib/screens/word_quiz_screen.dart`): 그림 보고 낱말 4지선다, 한 판 10문제. 풀 = picturable=Y 이면서 그림 있는 낱말(R1 31·R2 42·R3 151·R4 565), 보기는 같은 품사 먼저. 틀린 낱말은 `AchievementService.missedWords` → 복습 탭 「틀린 단어 다시」(맞히면 빠짐). 성과에 단어 그림 맞음(`daily.words`). 입구: 복습 탭 · 절벽 단어 화면 오른쪽 위 퀴즈 단추.
- 단어 그림: `art/en/manifest` 1,326개(2026-11-03 23시), 앱이 자동으로 씀. 목록 `talkverselab/talkversehanja` `talkverse_art/words/en.csv`(2,494어, R1 ≤189·R2 ≤318·R3 ≤825·R4 나머지 = 누적 55·60·70·80%) + `en_food.csv`(50) — 커밋 `36c09d3`. 새로 그릴 327어 + 음식 50 은 uk 세션 대기열.
- **앱 아이콘**(커밋 `24dcc09`, talkverse.uk 세션 생성 2026-11-04, 사용자 지시 "UK에 아이콘 요청해" → 글자 **「E」 사용자 결정**(첫 판 A = `7ba6938`)): 공통 톤 「E」(HelveticaNeue) — iOS 1024 기본·다크·틴티드, Android 적응형(monochrome 포함). uk 세션은 M6 에서 GitHub 푸시가 안 돼 이 세션이 푸시. 기준표 `branding/icon_apps.py`·`ICON_SPEC.md` 의 en 도 E 로 바뀜. 이 세션은 아이콘 파일을 직접 고치지 않는다.
- **2026-11-04 공통 변경 8가지**(일본어앱 세션 전달 사용자 지시, 원본 `~/talkverse/ja` 커밋 `9962316`, 공통 프롬프터 §5-1):
  ① 말풍선이 그림을 덮지 않음 — 「오늘의 컷」은 그림 아래 띠(`_LineStrip`, 화자 이름표 + 한 줄, 강세 표시 적용), 재생 화면 컷엔 말풍선 없음(아래 캡션이 보여 줌). 오버레이 말풍선 코드 삭제.
  ② 그림 카드 앞면 = 그림 + **한국어 뜻 크게** + 「이 말을 영어로 해 보세요」 → 탭 → 뒷면(영어·발음·독음·뜻·레마 칩).
  ③ 문장 레마 ↔ 단어장: 턴 `lemmas: [[표면형, 기본형, 읽기]]`(`tools/add_lemmas.py` — 규칙 기반 영어 기본형: 불규칙 표 + 접미사 규칙 + wordfreq 빈도, 기능어 제외, 읽기 칸은 빈 값), `lib/widgets/lemma_chips.dart`(절벽 단어 2,494어에 있으면 누르면 `word_sheet.dart`, 없으면 회색), 카드 뒷면·재생 캡션 아래. 없는 레마는 `data/review/write/missing_lemmas.csv` → uk 세션(단어·그림 제작). **회화가 아직 없어 CSV 는 머리글만.**
  ④ 시작 때 그림 기기 내려받기: `lib/services/content_sync.dart`(`/art/en/manifest` + `/art/en/scene/manifest` → `?v=` 해시 버전, 앱 지원 폴더 `art/` + `index.json`), `lib/screens/sync_screen.dart`(진행률·「나중에 — 앱 먼저 열기」), 모든 그림은 `artProvider(url)`(기기 파일 우선). 장면 컷 조회도 이 색인 먼저. `crypto` 의존성 추가.
  ⑤ 데이터 업데이트 번호 `assets/data/version.json` `{"db": 1}` — `lib/services/data_version.dart`: 번들 번호 ≠ 저장 번호면 기기 캐시(단어 그림 매니페스트)를 지우고 번호 저장. 기기 DB(SeedLoader)가 생기면 같은 번호로 전부 다시 채움. **데이터를 바꿀 때 이 번호만 올린다.**
  ⑥ 이름 없으면 묻기: `lib/widgets/learner_setup_dialog.dart` — `{name}` 이 있는 회화를 열 때 이름이 비면 이름·성별 창(앱 켠 뒤 한 번, 「나중에」 가능).
  ⑦ 여자 학습자 컷: `ArtService.sceneCut` 이 프로필 성별이 여자면 `<편id>_f` 컷 먼저(없으면 기본). **컷 요청문엔 옷·머리색 고정 묘사**(회화 ④ 때 적용).
  ⑧ 조연 캐릭터 시트: 회화에 반복 조연이 생기면 시트 2장(예: 카페·직장 / 셰어하우스·농구장)을 만들어 그 조연이 나오는 편의 컷 요청에 첨부 3·4 로(일본어 예 `~/talkverse/ja/data/review/art/cast_work_v1.jpg`·`cast_school_v1.jpg`). **회화 ④ 시작 때 할 일.**
  Play 프로텍트 「피싱」 경고는 스토어 밖 설치 + 개발 키 + 로그인 화면 조합이면 뜸(앱은 안전) — 근본 해결은 사용자 결정.
- Talkverse ID(uk 세션 등록 완료): client `en`, 딥링크 `talkverse.en://auth`, 플랜 `lang_en_life`(평생 14,900원), Apple `com.talkverse.englishUniverse.lifetime` / Google `lang_en`. **앱 연결(§11)은 사용자 「착수」 뒤.**

## 배포
- Android: `master` 푸시 → CI(`release.yml`) → `latest` 릴리스 → `tools/zealot_push.sh --ci "한 줄"`. 서명 SHA-1 `72:08:02:58:…:E7:BB`(M6 debug 키, Doppler `ANDROID_DEBUG_KEYSTORE_B64`). 리포 시크릿 `ANDROID_DEBUG_KEYSTORE_BASE64` 는 2026-11-03 노트북에서 `--body $v` 로 넣음 — **Windows 파이프(`|`)로 넣으면 비거나 깨진다.** CI 로그 `secret chars: 3492 / keystore bytes: 2618` 이 정상.
- PC 백업: `D:\OneDrive\app project\english_universe\english_universe-latest.apk`, iOS `…\ios\*.ipa`.
- iOS: `bash tools/ios_release.sh`(백그라운드, 8~12분). 첫 시도(빌드 2611030055)는 앱 레코드가 없어 실패(`Error Downloading App Information`), 사용자가 레코드를 만든 뒤 **빌드 2611030138 업로드 성공**(2026-11-03 01:39).

## 사용자 결정·지시 기록
- 저장소 이름 `talkverse-english`, 앱 이름 영어유니버스, 번들 `com.talkverse.englishUniverse` / `com.talkverse.english_universe`, Zealot 앱이름 「영어 유니버스」.
- 포인트색 인디고 `#4F46E5`(사이트 `--a #635bff` 가 공용 인디고와 같아 한 단계 진하게).
- 그림 요청은 한자 세션 경유(Grok 은 M4 Chrome, `~/talkverse/GROK_M4_LOGIN.md`). 글 시안도 사용자 확인으로 Grok 에 보낼 수 있음(영어 UX 01 때).

## 다음 할 일
1. **(사용자)** 아이패드 TestFlight 빌드 2611040244 · 폰 Zealot 빌드 8 설치·확인(아이콘 E + 그림 단어 퀴즈).
2. UX 시안 01 의 남은 칸: 「표현 카드」(덩어리·공손도 3단) 시트 자리, 강세 구간 탭 → 느리게 다시 재생. 데이터 필드(`chunks`·`politeness`) 생길 때.
3. 「소리 배우기」(강세·이어 말하기·약해지는 소리) 화면 — 콘텐츠 작업이 풀리면. (그림 단어 퀴즈는 2026-11-03 완료.)
3-1. 회화 ④ 를 시작하면: 편마다 `tools/add_lemmas.py` 로 lemmas 채우고 `missing_lemmas.csv` 를 uk 세션에 넘김, 조연 시트 2장(⑧), 컷 요청은 기본판 + 여자판(`_f`, 옷·머리색 고정)(⑦), 그림이 늘면 `version.json` 번호는 그대로(그림은 매니페스트 해시로 자동 갱신)·데이터가 바뀌면 번호 올림(⑤).
4. 회화(④)·로그인·결제(§11)는 사용자 지시 뒤.

## 전체 언어앱 공지(2026-11-03, talkverse.uk 전달 — 사용자 지시)
- Grok·Gemini: 로그인 원본 M4 `~/chrome-grok`, 쿠키 복사는 M4 안에서만(`~/chrome-grok-en/`), 자기 포트는 `GROK_CHROME_PORTS.md`, M6 에서는 ssh 터널. 상세 `~/talkverse/GROK_M4_LOGIN.md`, 예 `~/talkverse/ko/tools/grok_base.py`. 영어앱은 지금까지 한자 세션 경유로만 요청함.
- **2026-11-03 지시: 영어앱 세션은 Grok 작업을 시작하지 말고 대기**(사용자가 따로 지시할 때까지). M4 Grok 은 새 계정(원본 `~/chrome-grok`, 9222 — 예전 계정은 11/9 까지 한도, 새 계정엔 프로젝트·챗·GitHub 커넥터 없음). 시작할 때: ① 쿠키를 M4 안에서 `~/chrome-grok` 에서 다시 복사 ② 샘플 1~2개 먼저 시험 ③ 결과를 PushNotification 으로 사용자 통과 요청 ④ 통과 뒤 본작업.
- Grok 요청문 작성법(중국어앱 정리, 실제 통과 방식): `~/talkverse/GROK_PROMPT_GUIDE.md` — 전문가 모델·편마다 새 방·30초 뒤 다시 받기, 재작성은 '판정 말고 재작성'+'모든 줄 새로', 받은 답은 그대로 쓰지 말고 리뷰, 컷은 한 요청에 1장. 틀 파일 `~/talkverse/zh/tools/`(prompts/rewrite_grok.md·rewrite_request.py·scene_prompts.py·grok_*.py)를 복사해 코드만 바꾼다.
- M4 Grok 은 사용자 지시가 있을 때만 켠다. 한 번에 한 작업, 연 탭은 닫고 끝나면 Chrome 도 끈다.
- 회화(④) 때: 카오스 반전 30% 이상, 연애·플러팅 편마다 심쿵 한 줄(여성이 먼저 다가가는 편 더 많이), 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore), 새 편은 왕초보·초급 위주, 그림은 A·B 대사 한 쌍당 1컷(말풍선·글자 없음, 인물 기준 그림 첨부). 원칙 https://talkverse.uk/talkverse/dialogue-rules/

## 공통 절차
- M6 부하 규칙(2026-11-03): 빌드 시작 전 `pgrep -f flutter_tools.snapshot | wc -l` 이 3 이상이면 1분씩 대기, 시뮬레이터는 쓰고 바로 `xcrun simctl shutdown`. 이 앱 시뮬레이터 = `en-shots iPad Air 11`(iOS 26.5, UDID FFD4E03F-4171-4B78-AC33-11D3070768EF).
- 확인: `flutter analyze` · `flutter test`(17개) · `python3 tools/pane_shots.py <UDID> <스크래치> integration_test/dialogue_pane_test.dart` → `overflowed by` 0.
- 커밋은 경로 지정, `ios/Podfile.lock` 은 추적 안 함.
