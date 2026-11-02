# 영어앱 (Talkverse 언어앱) — 새 세션 (2026-11-02, 사용자 지시)

- 이 폴더는 **Talkverse 언어앱 공통 작업**(로그인·결제 연동, 캐릭터·UX 시안, 아이패드 빌드 등)을 받는 영어앱 세션 자리다. 원격 제어 이름 **"영어앱"**.
- **Grab(`~/talkverse/en`, 세션 이름 "grab")과는 별개 앱**이다 — Grab 은 언어앱 일괄 작업에서 제외(사용자 지시). 이 폴더에서 Grab 코드를 고치지 않는다.
- 아직 코드·저장소 없음. 첫 작업은 사용자 지시를 받아 시작한다(공통 프롬프트 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`, 가이드 `~/talkverse/TALKVERSE_ID_APP_GUIDE.md`). 회화·콘텐츠 작성 금지 상태는 그대로.

## 2026-11-03 — 일본어앱 구조 복제 시작(일본어앱 세션 전달, 공통 프롬프터 따름)
- ① 캐릭터 시트: 요청문 `data/review/art/req_chars_en.md`(뉴욕 브루클린 20대 6명 — Maya·Emma·Jake·Daniel + 학습자 남/여), 첨부 `data/review/art/ref/`. 한자 세션에 Grok 요청 보냄 → 결과 `data/review/art/chars_en_v1.md|.jpg` 대기.
- 강조색: 사이트 en 페이지 `--a #635bff` 가 UX 토큰 인디고와 같아 한 단계 진한 `#4F46E5` 를 앱 포인트색으로 가정(사용자 확인 전).
- 아직 저장소·코드 없음. 사용자 정할 것: GitHub 저장소(공개, 예 `talkverselab/talkverse-english`) 생성 여부, 앱 이름 「영어 유니버스」, 번들 ID `com.talkverse.englishUniverse`, Zealot 앱이름.

## 2026-11-03 오후 — 진행
- ① 캐릭터 v1 **사용자 통과** → `data/review/uxui/CHARACTERS.md`(장면 요청 때 항상 첨부, 운동화 로고 없음 주의).
- ② UX 글 시안 `data/review/uxui/sian_en_01.md`(이 세션 작성 — 소리 표시·표현 카드 칸 2개), 그림은 한자 세션 대기(`req_ux01_img_en.md` → `sian_en_01.jpg`·`sian_en_01_img.md`). 사용자 통과 전.
- ③ 바탕 코드 완료(일본어앱 구조, 로컬 git 만): analyze 0·test 4 통과, 아이패드 시뮬레이터(`en-shots iPad Air 11`, iOS 26.5, UDID FFD4E03F…) 스크린샷 11장 넘침 0. GitHub `talkverselab/talkverse-english` 는 세션 권한 정책이 생성을 막아 **사용자 생성 대기** → 생기면 첫 커밋·푸시 + 리포 시크릿 `ANDROID_DEBUG_KEYSTORE_BASE64`(Doppler `ANDROID_DEBUG_KEYSTORE_B64`).
- Talkverse ID(talkverse.uk 세션 등록 완료): client `en`, 딥링크 `talkverse.en://auth`, 플랜 `lang_en_life`(평생 14,900원), Apple `com.talkverse.englishUniverse.lifetime` / Google `lang_en`. 앱 연결(§11)은 사용자 「착수」 뒤.
