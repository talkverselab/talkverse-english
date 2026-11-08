/// 영어 소리표 — 「알파벳과 발음」 메뉴 데이터(공통 프롬프터 §5-3, 사용자 지시 2026-11-08, 일본어앱 「50음도와 발음」과 같은 틀).
/// 미국 발음 기준 IPA. 설명·비교는 한국어 화자용으로 이 세션이 직접 씀.
/// 모음 위치 x = 앞(0)~뒤(1), y = 닫힘(0)~열림(1) — 사다리꼴 그림에 영어(파랑)와 한국어(빨강)를 함께 찍는다.
library;

class EnSound {
  final String sym; // IPA
  final String word; // 예시 낱말(TTS 로 읽힌다)
  final String mark; // 예시 낱말 안에서 그 소리를 내는 글자(굵게)
  final String group; // vowel · diphthong · consonant
  final String spell; // 흔한 철자
  final String place; // 소리 나는 곳·입 모양
  final String korSim; // 비슷한 한국어 소리(근사 표기)
  final String korDiff; // 한국어와 다른 점
  final bool hard; // 한국어 화자가 특히 어려운 소리
  final (double, double)? vowel; // 모음 위치(영어)
  final List<(String, double, double)> korVowels; // 비교할 한국어 모음
  final List<String> pair; // 헷갈리는 짝 낱말(최소 대립쌍)
  const EnSound(this.sym, this.word, this.mark, this.group, this.spell, this.place, this.korSim, this.korDiff,
      {this.hard = false, this.vowel, this.korVowels = const [], this.pair = const []});
}

const _koI = ('ㅣ', 0.06, 0.06), _koE = ('ㅔ/ㅐ', 0.2, 0.45), _koA = ('ㅏ', 0.5, 0.92), _koEo = ('ㅓ', 0.74, 0.55),
    _koO = ('ㅗ', 0.86, 0.38), _koU = ('ㅜ', 0.9, 0.08), _koEu = ('ㅡ', 0.6, 0.1);

const enSounds = <EnSound>[
  // ── 단모음 ──
  EnSound('iː', 'see', 'ee', 'vowel', 'ee · ea · e', '입술을 옆으로 당기고 혀를 앞쪽 높이 — 길게 끈다.', '이—', '한국어 「이」보다 길고 긴장된 소리. 짧게 끊으면 /ɪ/ 로 들린다.',
      vowel: (0.05, 0.04), korVowels: [_koI], pair: ['seat', 'sit']),
  EnSound('ɪ', 'sit', 'i', 'vowel', 'i · y', '/iː/ 보다 혀를 조금 내리고 힘을 뺀다 — 짧게.', '이와 에 사이', '한국어 「이」로 내면 seat 처럼 들린다. 힘을 빼고 「에」 쪽으로 살짝.',
      hard: true, vowel: (0.18, 0.18), korVowels: [_koI, _koE], pair: ['ship', 'sheep']),
  EnSound('ɛ', 'bed', 'e', 'vowel', 'e · ea', '입을 반쯤 벌리고 혀는 앞쪽 가운데.', '에', '한국어 「에」와 거의 같다.',
      vowel: (0.2, 0.52), korVowels: [_koE], pair: ['bed', 'bad']),
  EnSound('æ', 'cat', 'a', 'vowel', 'a', '입을 크게 벌리고 혀끝은 아랫니 뒤에 — 「애」를 입 크게 벌려 길게.', '애(입을 크게)', '한국어 「애」보다 입을 훨씬 크게 벌린다. 작게 벌리면 bed 의 /ɛ/ 로 들린다.',
      hard: true, vowel: (0.24, 0.86), korVowels: [_koE, _koA], pair: ['bad', 'bed']),
  EnSound('ʌ', 'cup', 'u', 'vowel', 'u · o · ou', '입을 살짝 벌리고 힘을 빼고 짧게 — 혀는 가운데.', '어(짧게)', '한국어 「어」보다 입이 조금 더 벌어지고 짧다. 「아」와 「어」 사이.',
      vowel: (0.62, 0.62), korVowels: [_koEo, _koA], pair: ['cup', 'cop']),
  EnSound('ɑː', 'father', 'a', 'vowel', 'a · o(미국)', '입을 크게 벌리고 혀는 뒤쪽 아래 — 하품하듯.', '아—', '한국어 「아」보다 뒤에서 깊게. 미국 영어는 hot, stop 의 o 도 이 소리.',
      vowel: (0.85, 0.95), korVowels: [_koA], pair: ['cop', 'cup']),
  EnSound('ɔː', 'law', 'aw', 'vowel', 'aw · au · al', '입술을 동그랗게 내밀고 입을 꽤 벌린다.', '오와 어 사이', '한국어 「오」보다 입을 더 벌린다. 미국 일부 지역은 /ɑː/ 로 낸다.',
      vowel: (0.86, 0.66), korVowels: [_koO, _koEo]),
  EnSound('ʊ', 'book', 'oo', 'vowel', 'oo · u', '입술을 살짝만 둥글게, 힘을 빼고 짧게.', '우(힘 빼고)', '한국어 「우」로 길게 내면 /uː/ 가 된다. full 과 fool 을 구분.',
      hard: true, vowel: (0.74, 0.2), korVowels: [_koU, _koEu], pair: ['full', 'fool']),
  EnSound('uː', 'food', 'oo', 'vowel', 'oo · u · ew', '입술을 동그랗게 앞으로 내밀고 길게.', '우—', '한국어 「우」보다 입술을 더 내밀고 길게.',
      vowel: (0.92, 0.04), korVowels: [_koU], pair: ['fool', 'full']),
  EnSound('ə', 'about', 'a', 'vowel', '강세 없는 모든 모음', '힘을 완전히 빼고 입을 살짝 — 가장 약한 「어」.', '어(아주 약하게)', '영어에서 가장 흔한 소리. 강세 없는 모음은 철자와 상관없이 대부분 이 소리로 약해진다.',
      vowel: (0.5, 0.5), korVowels: [_koEo, _koEu]),
  EnSound('ɝː', 'bird', 'ir', 'vowel', 'ir · er · ur · or', '혀를 뒤로 말거나 뭉쳐 올린 채 「어」 — 끝까지 혀를 바닥에 붙이지 않는다.', '얼(혀를 만 채)', '한국어에 없는 소리. 「버드」처럼 r 을 빼면 안 된다. 혀를 만 채로 모음을 낸다.',
      hard: true, vowel: (0.5, 0.42), korVowels: [_koEo], pair: ['bird', 'bud']),
  // ── 이중모음 ──
  EnSound('eɪ', 'day', 'ay', 'diphthong', 'a_e · ai · ay', '「에」에서 「이」로 미끄러진다.', '에이', '「에」 하나로 끝내지 말고 「이」까지 이어 준다(day ≠ 데).', vowel: (0.14, 0.34), korVowels: [_koE, _koI]),
  EnSound('aɪ', 'time', 'i', 'diphthong', 'i_e · y · igh', '「아」에서 「이」로.', '아이', '한국어 「아이」와 비슷하지만 한 음절로 붙여 낸다.', vowel: (0.45, 0.9), korVowels: [_koA, _koI]),
  EnSound('ɔɪ', 'boy', 'oy', 'diphthong', 'oy · oi', '「오」에서 「이」로.', '오이', '한 음절로 붙여서. 「보이」가 아니라 「보이」를 한 박자에.', vowel: (0.84, 0.6), korVowels: [_koO, _koI]),
  EnSound('aʊ', 'now', 'ow', 'diphthong', 'ow · ou', '「아」에서 「우」로 입술을 모은다.', '아우', '한 음절로. now 를 「나우」 두 박자로 끊지 않는다.', vowel: (0.5, 0.9), korVowels: [_koA, _koU]),
  EnSound('oʊ', 'go', 'o', 'diphthong', 'o · oa · ow', '「오」에서 「우」로 입술을 더 모은다.', '오우', '「오」 하나로 끝내면 어색하다(go ≠ 고). 끝에 「우」를 붙인다.', vowel: (0.84, 0.36), korVowels: [_koO, _koU]),
  // ── 자음 ──
  EnSound('p', 'pen', 'p', 'consonant', 'p', '두 입술을 붙였다 터뜨린다 — 첫소리는 숨을 세게.', 'ㅍ', '첫소리는 한국어 「ㅍ」처럼 숨이 세다. 단어 끝은 터뜨리지 않고 닫기만 해도 된다.'),
  EnSound('b', 'bed', 'b', 'consonant', 'b', '두 입술을 붙였다 터뜨린다 — 성대가 울린다.', 'ㅂ', '단어 첫머리에서도 성대를 울린다. 한국어 첫소리 「ㅂ」는 무성음이라 pet 처럼 들릴 수 있다.'),
  EnSound('t', 'top', 't', 'consonant', 't', '혀끝을 윗잇몸에 댔다 뗀다.', 'ㅌ', '미국 영어는 모음 사이 t 가 「ㄹ」처럼 약해진다(water → 워러).'),
  EnSound('d', 'dog', 'd', 'consonant', 'd', '혀끝을 윗잇몸에 — 성대가 울린다.', 'ㄷ', '첫머리에서도 성대를 울린다.'),
  EnSound('k', 'key', 'k', 'consonant', 'k · c · ck', '혀 뒤를 입천장 뒤에 댔다 뗀다 — 첫소리는 숨을 세게.', 'ㅋ', '한국어 「ㅋ」와 비슷하다.'),
  EnSound('g', 'go', 'g', 'consonant', 'g', '혀 뒤를 입천장 뒤에 — 성대가 울린다.', 'ㄱ', '첫머리에서도 성대를 울린다(go ≠ 코).'),
  EnSound('f', 'fan', 'f', 'consonant', 'f · ph', '윗니를 아랫입술에 살짝 대고 바람을 낸다.', 'ㅍ와 ㅎ 사이', '한국어에 없는 소리. 「ㅍ」로 내면 pan 이 된다. 두 입술을 붙이지 말 것.',
      hard: true, pair: ['fan', 'pan']),
  EnSound('v', 'very', 'v', 'consonant', 'v', '/f/ 와 같은 자리에서 성대를 울린다.', 'ㅂ(윗니로)', '한국어에 없는 소리. 「ㅂ」로 내면 berry 가 된다. 윗니가 아랫입술에 닿아야 한다.',
      hard: true, pair: ['very', 'berry']),
  EnSound('θ', 'think', 'th', 'consonant', 'th', '혀끝을 윗니 끝에 살짝 물고 바람을 낸다.', 'ㅆ와 ㄸ 사이', '한국어에 없는 소리. 「ㅆ」로 내면 sink 가 된다. 혀가 이 사이로 보여야 한다.',
      hard: true, pair: ['think', 'sink']),
  EnSound('ð', 'this', 'th', 'consonant', 'th', '/θ/ 와 같은 자리에서 성대를 울린다.', 'ㄷ(혀를 이 사이에)', '「ㄷ」로 내면 dis 처럼 들린다. the, this, that 처럼 자주 나온다.',
      hard: true, pair: ['they', 'day']),
  EnSound('s', 'sun', 's', 'consonant', 's · c', '혀끝을 윗잇몸 가까이 — 바람을 가늘게.', 'ㅅ/ㅆ', 'si 를 「쉬」로 내지 않는다(see ≠ 쉬).'),
  EnSound('z', 'zoo', 'z', 'consonant', 'z · s', '/s/ 와 같은 자리에서 성대를 울린다 — 벌이 윙윙.', 'ㅈ와 ㅅ 사이', '한국어에 없는 소리. 「ㅈ」로 내면 jew 처럼 들린다. 혀가 입천장에 닿지 않는다.',
      hard: true, pair: ['zoo', 'jew']),
  EnSound('ʃ', 'she', 'sh', 'consonant', 'sh · ti · ci', '입술을 내밀고 혀를 조금 뒤로 — 「쉬」.', '쉬', '한국어 「쉬」와 비슷하지만 입술을 더 내민다.', pair: ['she', 'see']),
  EnSound('ʒ', 'vision', 's', 'consonant', 's · g', '/ʃ/ 와 같은 자리에서 성대를 울린다.', 'ㅈ(부드럽게)', '한국어에 없는 소리. 혀를 입천장에 대지 않고 「쥐」를 흘린다.', hard: true),
  EnSound('tʃ', 'chair', 'ch', 'consonant', 'ch · tch', '혀끝을 윗잇몸에 댔다가 「쉬」로 터뜨린다.', 'ㅊ', '한국어 「ㅊ」와 비슷하다. 입술을 조금 내민다.'),
  EnSound('dʒ', 'job', 'j', 'consonant', 'j · g · dge', '/tʃ/ 와 같은 자리에서 성대를 울린다.', 'ㅈ', '첫머리에서도 성대를 울린다.'),
  EnSound('m', 'man', 'm', 'consonant', 'm', '두 입술을 닫고 코로.', 'ㅁ', '한국어 「ㅁ」와 같다.'),
  EnSound('n', 'net', 'n', 'consonant', 'n', '혀끝을 윗잇몸에 대고 코로.', 'ㄴ', '한국어 「ㄴ」와 같다.'),
  EnSound('ŋ', 'sing', 'ng', 'consonant', 'ng · n(k)', '혀 뒤를 입천장 뒤에 대고 코로 — 받침 「ㅇ」.', '받침 ㅇ', '끝에 「그」를 붙이지 않는다(sing ≠ 싱그). 받침 「ㅇ」으로 끝낸다.'),
  EnSound('h', 'hat', 'h', 'consonant', 'h', '목에서 숨만 내보낸다.', 'ㅎ', '한국어 「ㅎ」와 같다. who, whole 의 w 는 소리 나지 않는다.'),
  EnSound('l', 'light', 'l', 'consonant', 'l', '혀끝을 윗잇몸에 꼭 붙인 채 소리를 낸다 — 단어 끝 l 은 혀 뒤를 들어 「얼」.', 'ㄹ(혀를 붙인 채)', '혀끝을 잇몸에 붙인다. 붙이지 않으면 r 로 들린다. 첫소리 l 은 「(을)라이트」처럼 미리 붙이고 시작.',
      hard: true, pair: ['light', 'right']),
  EnSound('r', 'right', 'r', 'consonant', 'r · wr', '혀끝을 어디에도 닿지 않게 뒤로 말고, 입술을 살짝 내민다 — 「(우)라이트」.', 'ㄹ(혀를 안 대고)', '한국어 「ㄹ」은 혀가 잇몸을 친다 — 그러면 l 로 들린다. 혀를 띄운 채 「우」로 시작하듯.',
      hard: true, pair: ['right', 'light']),
  EnSound('w', 'win', 'w', 'consonant', 'w · wh', '입술을 동그랗게 모았다가 편다.', '우(짧게)', 'wood, woman 처럼 「우」 뒤에 오는 w 도 입술을 한 번 더 모은다.'),
  EnSound('j', 'yes', 'y', 'consonant', 'y', '혀를 「이」 자리에 두었다가 미끄러진다.', '이(짧게)', 'year 와 ear 를 구분한다 — year 는 「이」를 먼저 미끄러뜨린다.', pair: ['year', 'ear']),
];

EnSound? soundOf(String sym) {
  for (final s in enSounds) {
    if (s.sym == sym) return s;
  }
  return null;
}

/// 알파벳 26자 — 글자 이름(IPA)·대표 소리·예시 낱말.
class EnLetter {
  final String upper, name, sound, word;
  const EnLetter(this.upper, this.name, this.sound, this.word);
  String get lower => upper.toLowerCase();
}

const enLetters = <EnLetter>[
  EnLetter('A', 'eɪ', 'æ', 'apple'), EnLetter('B', 'biː', 'b', 'ball'), EnLetter('C', 'siː', 'k', 'cat'), EnLetter('D', 'diː', 'd', 'dog'),
  EnLetter('E', 'iː', 'ɛ', 'egg'), EnLetter('F', 'ɛf', 'f', 'fish'), EnLetter('G', 'dʒiː', 'g', 'go'), EnLetter('H', 'eɪtʃ', 'h', 'hat'),
  EnLetter('I', 'aɪ', 'ɪ', 'it'), EnLetter('J', 'dʒeɪ', 'dʒ', 'jam'), EnLetter('K', 'keɪ', 'k', 'key'), EnLetter('L', 'ɛl', 'l', 'leg'),
  EnLetter('M', 'ɛm', 'm', 'map'), EnLetter('N', 'ɛn', 'n', 'net'), EnLetter('O', 'oʊ', 'ɑː', 'hot'), EnLetter('P', 'piː', 'p', 'pen'),
  EnLetter('Q', 'kjuː', 'k', 'queen'), EnLetter('R', 'ɑːr', 'r', 'red'), EnLetter('S', 'ɛs', 's', 'sun'), EnLetter('T', 'tiː', 't', 'top'),
  EnLetter('U', 'juː', 'ʌ', 'up'), EnLetter('V', 'viː', 'v', 'van'), EnLetter('W', 'dʌbəljuː', 'w', 'win'), EnLetter('X', 'ɛks', 'k', 'box'),
  EnLetter('Y', 'waɪ', 'j', 'yes'), EnLetter('Z', 'ziː', 'z', 'zoo'),
];
