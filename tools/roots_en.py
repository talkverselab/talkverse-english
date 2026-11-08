#!/usr/bin/env python3
"""뿌리(라틴·그리스 어근) 단어 패밀리 → assets/data/roots/roots_en.json (사용자 지시 2026-11-08 "뿌리 라틴어근 단어 패밀리 메뉴").
일본어앱 「패밀리 한자」(발음부) 자리의 영어 층(공통 프롬프터 §6-B). 어근·뜻·낱말 분해는 이 파일에 직접 쓴다 — 출처명은 적지 않는다.
낱말은 단어장(assets/data/words/en_words.csv, 2,494어)에 있는 것만 넣고 순위·구간·뜻을 붙인다. 단어장 밖 낱말은 `x` 표시로 조금만(가족을 잇는 데 꼭 필요한 것).
  python3 tools/roots_en.py        # JSON 다시 만들기 + 통계
형식: {"root": "port", "origin": "L", "meaning": "carry", "ko": "운반하다", "forms": ["port"],
       "words": [{"w": "import", "parts": ["im", "port", ""], "hint": "안으로(im) 운반 → 수입"}]}
parts = [앞가지, 어근 부분(변형 포함), 뒷가지]. hint = 조각이 뜻이 되는 한 줄(한국어)."""
import csv, json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PREFIX = {'a': '~에·~으로', 'ab': '떨어져', 'ac': '~에·향하여', 'ad': '~에·향하여', 'af': '~에·향하여', 'ap': '~에·향하여', 'as': '~에·향하여', 'at': '~에·향하여',
          'col': '함께', 'com': '함께', 'con': '함께·완전히', 'cor': '함께', 'de': '아래로·떨어져', 'dis': '떨어져·반대', 'di': '떨어져', 'e': '밖으로', 'ex': '밖으로',
          'ef': '밖으로', 'in': '안으로·아닌', 'im': '안으로·아닌', 'il': '아닌', 'inter': '사이', 'intro': '안으로', 'ob': '맞서·향하여', 'op': '맞서',
          'per': '끝까지·통하여', 'pre': '앞서', 'pro': '앞으로', 'pur': '앞으로', 're': '다시·뒤로', 'se': '따로', 'sub': '아래', 'sup': '아래', 'sus': '아래', 'sur': '위에',
          'trans': '건너', 'tele': '멀리', 'uni': '하나', 'bi': '둘', 'tri': '셋', 'auto': '스스로', 'super': '위에', 'under': '아래', 'over': '넘어', 'mis': '잘못', 'un': '아닌', 'non': '아닌', 'en': '안으로·되게', 'em': '안으로·되게', 'ir': '아닌'}

# (어근, 기원, 영어 뜻, 한국어 뜻, 변형들, [(낱말, 앞, 어근부분, 뒤, 힌트)])
R = [
 ('port', 'L', 'carry', '운반하다', ['port'], [
  ('port', '', 'port', '', '짐을 운반하는 곳 → 항구'),
  ('support', 'sup', 'port', '', '아래에서(sup) 받쳐 운반 → 지지하다'),
  ('important', 'im', 'port', 'ant', '안으로(im) 들여올 만한 → 중요한'),
  ('report', 're', 'port', '', '다시(re) 가져와 전함 → 보고하다'),
  ('transport', 'trans', 'port', '', '건너(trans) 운반 → 수송'),
  ('airport', 'air', 'port', '', '공중(air)의 항구 → 공항'),
  ('opportunity', 'op', 'port', 'unity', '항구 쪽으로(ob) 부는 순풍 → 기회'),
  ('sport', 's', 'port', '', 'dis(떨어져)+port — 일에서 떨어져 노는 것 → 운동'),
  ('export', 'ex', 'port', '', '밖으로(ex) 운반 → 수출', 'x'),
  ('import', 'im', 'port', '', '안으로(im) 운반 → 수입', 'x'),
 ]),
 ('spect', 'L', 'look', '보다', ['spec', 'spic'], [
  ('special', '', 'spec', 'ial', '눈에 띄는 종류(species)의 → 특별한'),
  ('especially', 'e', 'spec', 'ially', '특별히 → 특히'),
  ('specific', '', 'spec', 'ific', '종류를 만드는 → 구체적인'),
  ('species', '', 'spec', 'ies', '겉모습으로 나눈 것 → 종(種)'),
  ('respect', 're', 'spect', '', '다시(re) 돌아보다 → 존경'),
  ('expect', 'ex', 'pect', '', '밖을(ex) 내다보다(ex+spect, s 가 빠짐) → 기대하다', 'x'),
  ('inspect', 'in', 'spect', '', '안을(in) 들여다보다 → 점검하다', 'x'),
  ('perspective', 'per', 'spect', 'ive', '통하여(per) 보는 것 → 관점', 'x'),
 ]),
 ('duc', 'L', 'lead', '이끌다', ['duc', 'duct'], [
  ('produce', 'pro', 'duc', 'e', '앞으로(pro) 이끌어 내다 → 생산하다'),
  ('product', 'pro', 'duct', '', '앞으로 이끌어 낸 것 → 제품'),
  ('production', 'pro', 'duct', 'ion', '생산'),
  ('reduce', 're', 'duc', 'e', '뒤로(re) 이끌다 → 줄이다'),
  ('introduce', 'intro', 'duc', 'e', '안으로(intro) 이끌다 → 소개하다'),
  ('education', 'e', 'duc', 'ation', '밖으로(e) 이끌어 냄 → 교육'),
  ('educational', 'e', 'duc', 'ational', '교육의'),
  ('conduct', 'con', 'duct', '', '함께(con) 이끌다 → 지휘하다·행동', 'x'),
 ]),
 ('fer', 'L', 'carry, bring', '가져가다', ['fer'], [
  ('offer', 'of', 'fer', '', '맞은편으로(ob) 가져가다 → 제공하다'),
  ('different', 'dif', 'fer', 'ent', '따로(dis) 가져간 → 다른'),
  ('difference', 'dif', 'fer', 'ence', '차이'),
  ('transfer', 'trans', 'fer', '', '건너(trans) 가져가다 → 옮기다'),
  ('reference', 're', 'fer', 'ence', '다시(re) 가져가 댐 → 참고'),
  ('referred', 're', 'fer', 'red', '다시 가져가 말함 → 언급했다'),
  ('conference', 'con', 'fer', 'ence', '함께(con) 가져와 나눔 → 회의'),
  ('prefer', 'pre', 'fer', '', '앞에(pre) 가져다 두다 → 더 좋아하다', 'x'),
 ]),
 ('mit', 'L', 'send', '보내다', ['mit', 'miss'], [
  ('mission', '', 'miss', 'ion', '보내진 일 → 임무'),
  ('commission', 'com', 'miss', 'ion', '함께(com) 보내 맡김 → 위원회'),
  ('committee', 'com', 'mit', 'tee', '맡겨 보낸 사람들 → 위원회'),
  ('committed', 'com', 'mit', 'ted', '함께 보내 맡긴 → 헌신한'),
  ('permit', 'per', 'mit', '', '통과해(per) 보내다 → 허락하다', 'x'),
  ('submit', 'sub', 'mit', '', '아래로(sub) 보내다 → 제출하다', 'x'),
  ('admit', 'ad', 'mit', '', '~에(ad) 들여보내다 → 인정하다', 'x'),
 ]),
 ('pos', 'L', 'put, place', '놓다', ['pos', 'pon'], [
  ('position', '', 'pos', 'ition', '놓인 자리 → 위치'),
  ('positive', '', 'pos', 'itive', '놓인 그대로의 → 긍정적인'),
  ('possible', '', 'pos', 'sible', '(힘 potis) 할 수 있는 → 가능한 — pos 처럼 보이지만 사실은 힘(pot)에서'),
  ('purpose', 'pur', 'pos', 'e', '앞에(pro) 놓은 것 → 목적'),
  ('suppose', 'sup', 'pos', 'e', '아래에(sub) 놓다 → 가정하다'),
  ('propose', 'pro', 'pos', 'e', '앞에(pro) 놓다 → 제안하다'),
  ('opposite', 'op', 'pos', 'ite', '맞서(ob) 놓인 → 반대의'),
  ('post', '', 'pos', 't', '놓아 세운 것 → 기둥·게시'),
  ('compose', 'com', 'pos', 'e', '함께(com) 놓다 → 구성·작곡하다', 'x'),
 ]),
 ('scrib', 'L', 'write', '쓰다', ['scrib', 'script'], [
  ('describe', 'de', 'scrib', 'e', '아래로(de) 써 내려가다 → 묘사하다'),
  ('description', 'de', 'script', 'ion', '묘사'),
  ('script', '', 'script', '', '쓴 것 → 대본', 'x'),
  ('subscribe', 'sub', 'scrib', 'e', '아래에(sub) 이름을 쓰다 → 구독하다', 'x'),
 ]),
 ('struct', 'L', 'build', '세우다', ['struct'], [
  ('structure', '', 'struct', 'ure', '세운 것 → 구조'),
  ('construction', 'con', 'struct', 'ion', '함께(con) 세움 → 건설'),
  ('instruction', 'in', 'struct', 'ion', '안에(in) 세워 넣음 → 지시', 'x'),
  ('destroy', 'de', 'stro', 'y', '세운 것을 아래로(de) → 파괴하다', 'x'),
 ]),
 ('tract', 'L', 'pull, draw', '끌다', ['tract', 'treat'], [
  ('contract', 'con', 'tract', '', '함께(con) 끌어 묶음 → 계약'),
  ('treat', '', 'treat', '', '끌어 다루다 → 대하다·치료하다'),
  ('treatment', '', 'treat', 'ment', '치료'),
  ('attract', 'at', 'tract', '', '~에(ad) 끌다 → 끌어당기다', 'x'),
  ('extract', 'ex', 'tract', '', '밖으로(ex) 끌다 → 뽑아내다', 'x'),
 ]),
 ('vert', 'L', 'turn', '돌리다', ['vert', 'vers'], [
  ('version', '', 'vers', 'ion', '돌려 바꾼 것 → 판(版)'),
  ('conversation', 'con', 'vers', 'ation', '함께(con) 돌아다니며 어울림 → 대화'),
  ('university', 'uni', 'vers', 'ity', '하나로(uni) 돌아 모인 전체 → 대학'),
  ('convert', 'con', 'vert', '', '완전히(con) 돌리다 → 바꾸다', 'x'),
  ('advertise', 'ad', 'vert', 'ise', '~에(ad) 눈을 돌리게 하다 → 광고하다', 'x'),
 ]),
 ('vis', 'L', 'see', '보다', ['vis', 'vid', 'view'], [
  ('view', '', 'view', '', '보기·경치'),
  ('review', 're', 'view', '', '다시(re) 보다 → 검토·후기'),
  ('interview', 'inter', 'view', '', '사이에서(inter) 서로 봄 → 면접'),
  ('video', '', 'vid', 'eo', '나는 본다(video) → 영상'),
  ('visit', '', 'vis', 'it', '보러 가다 → 방문하다'),
  ('vision', '', 'vis', 'ion', '보는 것 → 시야·비전'),
  ('television', 'tele', 'vis', 'ion', '멀리(tele) 보기 → 텔레비전'),
  ('evidence', 'e', 'vid', 'ence', '밖으로(e) 보이는 것 → 증거'),
  ('provide', 'pro', 'vid', 'e', '앞을(pro) 내다보다 → 미리 마련하다·제공하다'),
  ('visible', '', 'vis', 'ible', '보일 수 있는 → 눈에 보이는', 'x'),
 ]),
 ('cap', 'L', 'take, seize', '잡다', ['cap', 'cept', 'ceiv', 'ceip'], [
  ('receive', 're', 'ceiv', 'e', '뒤로(re) 받아 잡다 → 받다'),
  ('accept', 'ac', 'cept', '', '~에(ad) 잡아 들이다 → 받아들이다'),
  ('except', 'ex', 'cept', '', '밖으로(ex) 잡아 내다 → 제외하고'),
  ('concept', 'con', 'cept', '', '함께(con) 잡아 모은 생각 → 개념'),
  ('capable', '', 'cap', 'able', '잡을 수 있는 → 할 수 있는'),
  ('capacity', '', 'cap', 'acity', '잡아 담을 양 → 용량·능력'),
  ('captain', '', 'cap', 'tain', '머리(caput) → 우두머리 — 머리(cap)에서 온 사촌'),
  ('capital', '', 'cap', 'ital', '머리의 → 수도·자본 — 머리(cap)에서 온 사촌'),
  ('escape', 'es', 'cap', 'e', '밖으로(ex) 망토(cappa)를 벗어 두고 → 달아나다'),
 ]),
 ('ced', 'L', 'go, yield', '가다·물러나다', ['ced', 'ceed', 'cess'], [
  ('process', 'pro', 'cess', '', '앞으로(pro) 가는 것 → 과정'),
  ('success', 'suc', 'cess', '', '아래에서 뒤따라(sub) 가서 닿음 → 성공'),
  ('successful', 'suc', 'cess', 'ful', '성공적인'),
  ('access', 'ac', 'cess', '', '~에(ad) 가 닿음 → 접근'),
  ('necessary', 'ne', 'cess', 'ary', '물러날(cess) 수 없는(ne) → 필요한'),
  ('proceed', 'pro', 'ceed', '', '앞으로(pro) 가다 → 나아가다', 'x'),
  ('exceed', 'ex', 'ceed', '', '밖으로(ex) 넘어가다 → 넘다', 'x'),
 ]),
 ('form', 'L', 'shape', '모양', ['form'], [
  ('form', '', 'form', '', '모양·형태'),
  ('information', 'in', 'form', 'ation', '안에(in) 모양을 넣어 줌 → 정보'),
  ('perform', 'per', 'form', '', '끝까지(per) 모양을 이루다 → 수행하다'),
  ('performance', 'per', 'form', 'ance', '공연·성과'),
  ('former', '', 'form', 'er', '먼저 있던 모양의 → 이전의'),
  ('platform', 'plat', 'form', '', '평평한(plat) 모양 → 단·플랫폼'),
  ('uniform', 'uni', 'form', '', '하나의(uni) 모양 → 제복·균일한', 'x'),
  ('transform', 'trans', 'form', '', '건너(trans) 모양을 바꾸다 → 변형하다', 'x'),
 ]),
 ('ject', 'L', 'throw', '던지다', ['ject'], [
  ('project', 'pro', 'ject', '', '앞으로(pro) 던진 것 → 계획·프로젝트'),
  ('subject', 'sub', 'ject', '', '아래에(sub) 던져 놓인 것 → 주제·과목'),
  ('object', 'ob', 'ject', '', '맞서(ob) 던져진 것 → 물체·반대하다', 'x'),
  ('reject', 're', 'ject', '', '뒤로(re) 던지다 → 거절하다', 'x'),
  ('inject', 'in', 'ject', '', '안으로(in) 던지다 → 주사하다', 'x'),
 ]),
 ('fac', 'L', 'make, do', '만들다', ['fac', 'fect', 'fic', 'fit'], [
  ('fact', '', 'fac', 't', '만들어진 일 → 사실'),
  ('factor', '', 'fac', 'tor', '만드는 것 → 요인'),
  ('effect', 'ef', 'fect', '', '밖으로(ex) 만들어 낸 것 → 효과'),
  ('effective', 'ef', 'fect', 'ive', '효과적인'),
  ('affect', 'af', 'fect', '', '~에(ad) 작용을 만들다 → 영향을 주다'),
  ('perfect', 'per', 'fect', '', '끝까지(per) 만든 → 완벽한'),
  ('office', 'of', 'fic', 'e', '일(opus)을 만드는 곳 → 사무실'),
  ('officer', 'of', 'fic', 'er', '공무 하는 사람 → 경관·장교'),
  ('official', 'of', 'fic', 'ial', '공식적인'),
  ('difficult', 'dif', 'fic', 'ult', '만들기 쉽지(facilis) 않은(dis) → 어려운'),
  ('facility', '', 'fac', 'ility', '하기 쉽게 하는 것 → 시설'),
  ('benefit', 'bene', 'fit', '', '좋게(bene) 만든 것 → 이익', 'x'),
 ]),
 ('ven', 'L', 'come', '오다', ['ven', 'vent'], [
  ('event', 'e', 'vent', '', '밖으로(e) 나온 일 → 행사·사건'),
  ('eventually', 'e', 'vent', 'ually', '결국'),
  ('prevent', 'pre', 'vent', '', '앞서(pre) 와서 막다 → 예방하다'),
  ('revenue', 're', 'ven', 'ue', '되돌아(re) 오는 것 → 수익'),
  ('convention', 'con', 'vent', 'ion', '함께(con) 옴 → 대회·관습', 'x'),
  ('adventure', 'ad', 'vent', 'ure', '~에게(ad) 다가올 일 → 모험', 'x'),
 ]),
 ('sta', 'L', 'stand', '서다', ['sta', 'stat', 'sist', 'stit'], [
  ('state', '', 'stat', 'e', '서 있는 모습 → 상태·국가'),
  ('station', '', 'stat', 'ion', '서는 곳 → 역'),
  ('statement', '', 'stat', 'ement', '세워 말한 것 → 진술'),
  ('status', '', 'stat', 'us', '서 있는 자리 → 지위'),
  ('statistics', '', 'stat', 'istics', '국가(state)의 수치 → 통계'),
  ('stand', '', 'sta', 'nd', '서다'),
  ('standard', '', 'sta', 'ndard', '세워 둔 기준 → 표준'),
  ('stage', '', 'sta', 'ge', '서는 자리 → 무대·단계'),
  ('distance', 'di', 'sta', 'nce', '떨어져(dis) 서 있음 → 거리'),
  ('instead', 'in', 'ste', 'ad', '그 자리에(in stead) → 대신에'),
  ('assistant', 'as', 'sist', 'ant', '옆에(ad) 서 있는 사람 → 조수'),
  ('institute', 'in', 'stit', 'ute', '안에(in) 세운 것 → 기관'),
  ('establish', 'e', 'sta', 'blish', '굳게 세우다 → 설립하다'),
  ('circumstances', 'circum', 'sta', 'nces', '둘레에(circum) 서 있는 것 → 상황'),
  ('estate', 'e', 'stat', 'e', '서 있는 재산 → 부동산'),
  ('restaurant', 're', 'sta', 'urant', '다시(re) 세우는 곳 → 기운을 회복하는 곳 → 식당'),
  ('resist', 're', 'sist', '', '맞서(re) 서다 → 저항하다', 'x'),
 ]),
 ('tain', 'L', 'hold', '붙잡다', ['tain', 'ten', 'tin'], [
  ('contain', 'con', 'tain', '', '함께(con) 붙잡아 두다 → 담다'),
  ('content', 'con', 'ten', 't', '담긴 것 → 내용'),
  ('maintain', 'main', 'tain', '', '손(manu)에 붙잡다 → 유지하다'),
  ('continue', 'con', 'tin', 'ue', '함께(con) 붙잡아 이어 가다 → 계속하다'),
  ('entertainment', 'enter', 'tain', 'ment', '사이에서(inter) 붙잡아 둠 → 오락'),
  ('obtain', 'ob', 'tain', '', '향하여(ob) 붙잡다 → 얻다', 'x'),
  ('retain', 're', 'tain', '', '뒤로(re) 붙잡다 → 보유하다', 'x'),
 ]),
 ('gen', 'L', 'birth, kind', '태어남·종류', ['gen'], [
  ('general', '', 'gen', 'eral', '한 종류 전체에 걸친 → 일반적인'),
  ('generation', '', 'gen', 'eration', '태어난 무리 → 세대'),
  ('agent', 'a', 'gen', 't', '행하는(ag) 사람 → 대리인 — ag(행하다)에서, 모양만 닮음'),
  ('agency', 'a', 'gen', 'cy', '대리하는 곳 → 기관 — ag(행하다)에서'),
  ('intelligence', 'intel', 'lig', 'ence', '사이에서(inter) 골라(leg) 읽는 힘 → 지능 — leg(고르다)에서'),
  ('genuine', '', 'gen', 'uine', '태어난 그대로의 → 진짜의', 'x'),
  ('gender', '', 'gen', 'der', '종류 → 성(性)', 'x'),
 ]),
 ('sens', 'L', 'feel', '느끼다', ['sens', 'sent'], [
  ('sense', '', 'sens', 'e', '느낌·감각'),
  ('essential', 'ess', 'ent', 'ial', '있음(esse)의 핵심 → 필수적인 — esse(있다)에서'),
  ('sentence', '', 'sent', 'ence', '느낀 바를 말한 것 → 문장·판결', 'x'),
  ('consent', 'con', 'sent', '', '함께(con) 느끼다 → 동의', 'x'),
 ]),
 ('act', 'L', 'do, drive', '행하다', ['act', 'ag'], [
  ('act', '', 'act', '', '행하다·행동'),
  ('action', '', 'act', 'ion', '행동'),
  ('active', '', 'act', 'ive', '행하는 → 활동적인'),
  ('activity', '', 'act', 'ivity', '활동'),
  ('actor', '', 'act', 'or', '행하는 사람 → 배우'),
  ('actually', '', 'act', 'ually', '실제 행한 대로 → 사실은'),
  ('exactly', 'ex', 'act', 'ly', '끝까지 몰아간(ex) → 정확히'),
  ('reaction', 're', 'act', 'ion', '되받아(re) 행함 → 반응'),
  ('agent', '', 'ag', 'ent', '행하는 사람 → 대리인'),
  ('agency', '', 'ag', 'ency', '대리하는 곳 → 기관'),
  ('contact', 'con', 'tact', '', '함께(con) 닿음 → 접촉 — tact(닿다)에서'),
 ]),
 ('mov', 'L', 'move', '움직이다', ['mov', 'mot', 'mob'], [
  ('move', '', 'mov', 'e', '움직이다'),
  ('movement', '', 'mov', 'ement', '움직임·운동'),
  ('movie', '', 'mov', 'ie', '움직이는 그림 → 영화'),
  ('remove', 're', 'mov', 'e', '뒤로(re) 움직이다 → 치우다'),
  ('mobile', '', 'mob', 'ile', '움직일 수 있는 → 이동식·휴대폰'),
  ('emotional', 'e', 'mot', 'ional', '밖으로(e) 움직여 나오는 → 감정의'),
  ('motor', '', 'mot', 'or', '움직이게 하는 것 → 모터', 'x'),
  ('promote', 'pro', 'mot', 'e', '앞으로(pro) 움직이다 → 승진시키다·홍보하다', 'x'),
 ]),
 ('ply', 'L', 'fold', '접다', ['ply', 'plic', 'plex', 'ple'], [
  ('apply', 'ap', 'ply', '', '~에(ad) 접어 대다 → 적용·지원하다'),
  ('application', 'ap', 'plic', 'ation', '적용·지원·앱'),
  ('supply', 'sup', 'ply', '', '아래에서(sub) 채워 접어 넣다 → 공급하다'),
  ('complex', 'com', 'plex', '', '함께(com) 접힌 → 복잡한'),
  ('simple', 'sim', 'ple', '', '한 번(sim) 접힌 → 단순한'),
  ('multiple', 'multi', 'ple', '', '여러 번(multi) 접힌 → 다수의'),
  ('couple', 'cou', 'ple', '', '함께(co) 묶인(copula) 둘 → 한 쌍 — 사촌 뿌리'),
  ('complete', 'com', 'ple', 'te', '완전히(com) 채운(plere) → 완성된 — ple(채우다)에서'),
  ('reply', 're', 'ply', '', '되(re) 접어 보내다 → 답하다', 'x'),
 ]),
 ('sign', 'L', 'mark', '표시', ['sign'], [
  ('sign', '', 'sign', '', '표시·서명하다'),
  ('signal', '', 'sign', 'al', '표시 → 신호'),
  ('design', 'de', 'sign', '', '표시해 내려(de) 그리다 → 설계'),
  ('significant', '', 'sign', 'ificant', '표시를 만드는 → 중요한'),
  ('assign', 'as', 'sign', '', '~에(ad) 표시해 주다 → 배정하다', 'x'),
 ]),
 ('equ', 'L', 'equal', '같은', ['equ'], [
  ('equal', '', 'equ', 'al', '같은'),
  ('equipment', '', 'equip', 'ment', '배(skip)에 갖춘 것 → 장비 — 모양만 닮은 다른 뿌리'),
  ('adequate', 'ad', 'equ', 'ate', '~에(ad) 같게 맞춘 → 적절한', 'x'),
 ]),
 ('quir', 'L', 'ask, seek', '묻다·구하다', ['quir', 'ques', 'quest'], [
  ('question', '', 'quest', 'ion', '묻는 것 → 질문'),
  ('request', 're', 'quest', '', '다시(re) 구하다 → 요청'),
  ('require', 're', 'quir', 'e', '다시(re) 구하다 → 필요로 하다'),
  ('requirement', 're', 'quir', 'ement', '요건'),
  ('acquire', 'ac', 'quir', 'e', '~에(ad) 더해 구하다 → 얻다', 'x'),
 ]),
 ('cur', 'L', 'run', '달리다', ['cur', 'cours'], [
  ('course', '', 'cours', 'e', '달리는 길 → 과정·강좌'),
  ('current', '', 'cur', 'rent', '달리고 있는 → 현재의·흐름'),
  ('currently', '', 'cur', 'rently', '현재'),
  ('occur', 'oc', 'cur', '', '맞은편으로(ob) 달려오다 → 일어나다', 'x'),
 ]),
 ('part', 'L', 'part, divide', '부분·나누다', ['part'], [
  ('part', '', 'part', '', '부분'),
  ('party', '', 'part', 'y', '한쪽 편 사람들 → 모임·정당'),
  ('partner', '', 'part', 'ner', '한 부분을 가진 사람 → 동반자'),
  ('particular', '', 'part', 'icular', '작은 부분의 → 특정한'),
  ('department', 'de', 'part', 'ment', '나뉜 곳 → 부서'),
  ('apart', 'a', 'part', '', '한쪽으로(a) 나뉘어 → 떨어져'),
  ('apartment', 'a', 'part', 'ment', '나뉜 거처 → 아파트'),
  ('participate', '', 'part', 'icipate', '부분을 잡다(cap) → 참여하다', 'x'),
 ]),
 ('cent', 'L', 'hundred', '백(100)', ['cent'], [
  ('percent', 'per', 'cent', '', '백(cent) 마다(per) → 퍼센트'),
  ('century', '', 'cent', 'ury', '백 년 → 세기'),
  ('cent', '', 'cent', '', '백분의 일 달러 → 센트'),
  ('center', '', 'cent', 'er', '원의 가운데 점(kentron) → 중심 — 모양만 닮은 그리스 뿌리'),
  ('central', '', 'centr', 'al', '중심의 — kentron 에서'),
  ('recent', 're', 'cent', '', '새로운(recens) → 최근의 — 모양만 닮음'),
 ]),
 ('fin', 'L', 'end, limit', '끝·경계', ['fin'], [
  ('final', '', 'fin', 'al', '끝의 → 마지막의'),
  ('finally', '', 'fin', 'ally', '마침내'),
  ('finish', '', 'fin', 'ish', '끝내다'),
  ('fine', '', 'fin', 'e', '끝까지 다듬은 → 좋은·벌금'),
  ('financial', '', 'fin', 'ancial', '빚을 끝냄(fin) → 재정의'),
  ('finance', '', 'fin', 'ance', '금융'),
  ('definitely', 'de', 'fin', 'itely', '경계를 완전히(de) 그은 → 분명히'),
  ('define', 'de', 'fin', 'e', '경계를 긋다 → 정의하다', 'x'),
  ('infinite', 'in', 'fin', 'ite', '끝이 없는(in) → 무한한', 'x'),
 ]),
 ('grad', 'L', 'step', '걸음', ['grad', 'gress'], [
  ('grade', '', 'grad', 'e', '걸음·단계 → 학년·등급'),
  ('progress', 'pro', 'gress', '', '앞으로(pro) 걸음 → 진보'),
  ('congress', 'con', 'gress', '', '함께(con) 걸어 모임 → 의회'),
  ('graduate', '', 'grad', 'uate', '단계를 다 밟다 → 졸업하다', 'x'),
  ('aggressive', 'ag', 'gress', 'ive', '~에게(ad) 걸어 다가가는 → 공격적인', 'x'),
 ]),
 ('leg', 'L', 'choose, read, law', '고르다·읽다·법', ['leg', 'lect', 'lig'], [
  ('legal', '', 'leg', 'al', '법의 → 합법적인'),
  ('illegal', 'il', 'leg', 'al', '법이 아닌(in) → 불법의'),
  ('college', 'col', 'leg', 'e', '함께(col) 뽑힌 동료들 → 대학'),
  ('election', 'e', 'lect', 'ion', '밖으로(e) 골라냄 → 선거'),
  ('elect', 'e', 'lect', '', '골라내다 → 선출하다'),
  ('select', 'se', 'lect', '', '따로(se) 고르다 → 고르다'),
  ('selection', 'se', 'lect', 'ion', '선택'),
  ('collect', 'col', 'lect', '', '함께(col) 모아 고르다 → 모으다'),
  ('collection', 'col', 'lect', 'ion', '수집·모음'),
  ('intelligence', 'intel', 'lig', 'ence', '사이에서(inter) 골라 읽는 힘 → 지능'),
  ('lecture', '', 'lect', 'ure', '읽어 주는 것 → 강의', 'x'),
 ]),
 ('man', 'L', 'hand', '손', ['man'], [
  ('manage', '', 'man', 'age', '손으로 다루다 → 관리하다'),
  ('manager', '', 'man', 'ager', '관리자'),
  ('management', '', 'man', 'agement', '경영'),
  ('demand', 'de', 'man', 'd', '손에 맡겨(mandare) 내려(de) 요구 → 요구하다'),
  ('command', 'com', 'man', 'd', '손에 맡기다(mandare) → 명령하다'),
  ('maintain', 'main', 'tain', '', '손(manu)에 붙잡다(tain) → 유지하다'),
  ('manual', '', 'man', 'ual', '손의 → 수동·설명서', 'x'),
  ('manufacture', 'manu', 'fact', 'ure', '손으로(manu) 만듦(fac) → 제조', 'x'),
 ]),
 ('mem', 'L', 'remember', '기억하다', ['mem'], [
  ('remember', 're', 'mem', 'ber', '다시(re) 마음에 두다 → 기억하다'),
  ('memory', '', 'mem', 'ory', '기억'),
  ('member', '', 'mem', 'ber', '몸의 지체(membrum) → 구성원 — 모양만 닮은 다른 뿌리'),
  ('memorial', '', 'mem', 'orial', '기억하기 위한 → 기념의', 'x'),
 ]),
 ('nat', 'L', 'born', '태어나다', ['nat'], [
  ('nation', '', 'nat', 'ion', '같이 태어난 무리 → 국가'),
  ('national', '', 'nat', 'ional', '국가의'),
  ('international', 'inter', 'nat', 'ional', '나라 사이의(inter) → 국제적인'),
  ('nature', '', 'nat', 'ure', '태어난 그대로 → 자연'),
  ('natural', '', 'nat', 'ural', '자연의'),
  ('native', '', 'nat', 'ive', '태어난 곳의 → 원주민·모국의'),
  ('innate', 'in', 'nat', 'e', '안에(in) 타고난 → 선천적인', 'x'),
 ]),
 ('nov', 'L', 'new', '새로운', ['nov'], [
  ('novel', '', 'nov', 'el', '새로운 이야기 → 소설'),
  ('november', '', 'nov', 'ember', '아홉(novem) 번째 달 → 11월 — 모양만 닮은 다른 뿌리(아홉)'),
  ('innovation', 'in', 'nov', 'ation', '안에(in) 새것을 넣음 → 혁신', 'x'),
  ('renovate', 're', 'nov', 'ate', '다시(re) 새롭게 → 개조하다', 'x'),
 ]),
 ('pass', 'L', 'step, pass', '걸음·지나다', ['pass', 'pac'], [
  ('pass', '', 'pass', '', '지나가다·통과하다'),
  ('passed', '', 'pass', 'ed', '지나갔다'),
  ('passing', '', 'pass', 'ing', '지나가는'),
  ('space', 's', 'pac', 'e', '펼친(spatium) 자리 → 공간 — 모양만 닮음'),
  ('passenger', '', 'pass', 'enger', '지나가는 사람 → 승객', 'x'),
  ('passport', '', 'pass', 'port', '항구(port)를 지나가는 허가 → 여권', 'x'),
 ]),
 ('pat', 'L', 'suffer, feel', '겪다·느끼다', ['pat', 'pass'], [
  ('patient', '', 'pat', 'ient', '겪는 사람 → 환자, 참는 → 참을성 있는'),
  ('passion', '', 'pass', 'ion', '겪는 강한 느낌 → 열정', 'x'),
  ('compassion', 'com', 'pass', 'ion', '함께(com) 겪음 → 동정', 'x'),
 ]),
 ('pend', 'L', 'hang, weigh, pay', '매달다·재다·치르다', ['pend', 'pens'], [
  ('spend', 's', 'pend', '', '무게를 재어 치르다(expendere) → 쓰다'),
  ('spending', 's', 'pend', 'ing', '지출'),
  ('expensive', 'ex', 'pens', 'ive', '밖으로(ex) 많이 치르는 → 비싼'),
  ('independent', 'inde', 'pend', 'ent', '매달려(de) 있지 않은(in) → 독립적인'),
  ('depend', 'de', 'pend', '', '~에(de) 매달리다 → 의존하다', 'x'),
  ('pension', '', 'pens', 'ion', '치러 주는 돈 → 연금', 'x'),
 ]),
 ('prim', 'L', 'first', '첫째', ['prim', 'prin'], [
  ('primary', '', 'prim', 'ary', '첫째의 → 주요한·초등의'),
  ('prime', '', 'prim', 'e', '첫째의 → 최고의·총리(prime minister)'),
  ('prince', '', 'prin', 'ce', '첫째로(prim) 잡은(cap) 자 → 왕자'),
  ('principal', '', 'prin', 'cipal', '첫째인 → 주요한·교장', 'x'),
  ('principle', '', 'prin', 'ciple', '첫째 되는 것 → 원칙', 'x'),
 ]),
 ('reg', 'L', 'rule, straight', '다스리다·곧게', ['reg', 'rect'], [
  ('region', '', 'reg', 'ion', '다스리는 범위 → 지역'),
  ('regional', '', 'reg', 'ional', '지역의'),
  ('regular', '', 'reg', 'ular', '규칙(regula)에 맞는 → 규칙적인'),
  ('direct', 'di', 'rect', '', '곧게(rect) 따로(dis) 세운 → 직접의·지시하다'),
  ('direction', 'di', 'rect', 'ion', '방향'),
  ('director', 'di', 'rect', 'or', '방향을 정하는 사람 → 감독·이사'),
  ('correct', 'cor', 'rect', '', '함께(com) 곧게 → 올바른'),
  ('regarding', 're', 'gard', 'ing', '지켜보다(guard) → ~에 관하여 — 모양만 닮은 다른 뿌리'),
 ]),
 ('sol', 'L', 'alone, whole', '혼자·온전한', ['sol'], [
  ('solo', '', 'sol', 'o', '혼자 → 독주'),
  ('solid', '', 'sol', 'id', '온전한·단단한'),
  ('soldier', '', 'sol', 'dier', '금화(solidus)를 받는 자 → 군인'),
  ('solution', '', 'sol', 'ution', '풀어(solvere) 냄 → 해결 — solv(풀다)에서'),
  ('absolutely', 'ab', 'sol', 'utely', '완전히(ab) 풀린 → 절대적으로 — solv(풀다)에서'),
  ('sold', '', 'sol', 'd', 'sell 의 과거 — 모양만 닮은 영어 고유어'),
 ]),
 ('tend', 'L', 'stretch', '뻗다', ['tend', 'tens', 'tent'], [
  ('attention', 'at', 'tent', 'ion', '~에(ad) 마음을 뻗음 → 주의'),
  ('intend', 'in', 'tend', '', '~으로(in) 마음을 뻗다 → 의도하다'),
  ('extended', 'ex', 'tend', 'ed', '밖으로(ex) 뻗은 → 연장된'),
  ('potential', 'pot', 'ent', 'ial', '힘(potis) 있는 → 잠재적인 — pot(힘)에서'),
  ('tension', '', 'tens', 'ion', '뻗어 당긴 상태 → 긴장', 'x'),
  ('tent', '', 'tent', '', '펼쳐 친 것 → 텐트', 'x'),
 ]),
 ('terr', 'L', 'earth', '땅', ['terr'], [
  ('territory', '', 'terr', 'itory', '땅의 범위 → 영토'),
  ('terrible', '', 'terr', 'ible', '떨게(terrere) 하는 → 끔찍한 — 땅이 아니라 「떨다」 뿌리'),
  ('terrace', '', 'terr', 'ace', '땅을 돋운 곳 → 테라스', 'x'),
 ]),
 ('ver', 'L', 'true', '참된', ['ver'], [
  ('very', '', 'ver', 'y', '참된 → 진짜로·매우'),
  ('verify', '', 'ver', 'ify', '참되게 만들다 → 확인하다', 'x'),
  ('version', '', 'vers', 'ion', '돌리다(vert) → 판 — 모양만 닮음'),
 ]),
 ('serv', 'L', 'serve, keep', '섬기다·지키다', ['serv'], [
  ('serve', '', 'serv', 'e', '섬기다·제공하다'),
  ('service', '', 'serv', 'ice', '섬김 → 서비스'),
  ('reserve', 're', 'serv', 'e', '뒤에(re) 지켜 두다 → 예약·비축하다'),
  ('deserve', 'de', 'serv', 'e', '끝까지(de) 섬겨 받을 만하다 → ~할 자격이 있다'),
  ('conservative', 'con', 'serv', 'ative', '함께(con) 지키는 → 보수적인'),
  ('observe', 'ob', 'serv', 'e', '향하여(ob) 지켜보다 → 관찰하다', 'x'),
 ]),
 ('sci', 'L', 'know', '알다', ['sci'], [
  ('science', '', 'sci', 'ence', '아는 것 → 과학'),
  ('scientific', '', 'sci', 'entific', '과학의'),
  ('conscious', 'con', 'sci', 'ous', '함께(con) 아는 → 의식하는', 'x'),
 ]),
 ('prob', 'L', 'test, prove', '시험하다·증명하다', ['prob', 'prov'], [
  ('problem', 'pro', 'ble', 'm', '앞에(pro) 던져진(ballein) 것 → 문제 — 그리스 뿌리, 모양만 닮음'),
  ('probably', '', 'prob', 'ably', '증명될 만한 → 아마'),
  ('prove', '', 'prov', 'e', '증명하다'),
  ('improve', 'im', 'prov', 'e', '이익(prou)으로 들이다 → 개선하다'),
  ('approve', 'ap', 'prov', 'e', '~에(ad) 좋다고 증명하다 → 승인하다'),
 ]),
 ('cre', 'L', 'grow, make', '자라다·만들다', ['cre', 'cresc'], [
  ('create', '', 'cre', 'ate', '자라게 하다 → 창조하다'),
  ('creative', '', 'cre', 'ative', '창조적인'),
  ('increase', 'in', 'cre', 'ase', '안으로(in) 자라다 → 증가하다'),
  ('decrease', 'de', 'cre', 'ase', '아래로(de) 자라다 → 감소하다', 'x'),
  ('recruit', 're', 'cru', 'it', '다시(re) 자라나게 → 모집하다', 'x'),
 ]),
 ('log', 'G', 'word, study', '말·학문', ['log'], [
  ('technology', 'techno', 'log', 'y', '기술(techne)의 학문 → 기술'),
  ('blog', 'b', 'log', '', 'web + log(기록) → 블로그 — 영어 log(통나무·기록)에서'),
  ('apology', 'apo', 'log', 'y', '떨어져(apo) 변호하는 말 → 사과', 'x'),
  ('dialogue', 'dia', 'log', 'ue', '사이를(dia) 오가는 말 → 대화', 'x'),
  ('logic', '', 'log', 'ic', '말·이치 → 논리', 'x'),
 ]),
 ('graph', 'G', 'write', '쓰다·그리다', ['graph', 'gram'], [
  ('program', 'pro', 'gram', '', '앞에(pro) 써 둔 것 → 프로그램'),
  ('photograph', 'photo', 'graph', '', '빛(photo)으로 그림 → 사진', 'x'),
  ('paragraph', 'para', 'graph', '', '옆에(para) 쓴 표시 → 단락', 'x'),
  ('grammar', '', 'gram', 'mar', '글자의 기술 → 문법', 'x'),
 ]),
 ('tele', 'G', 'far', '멀리', ['tele'], [
  ('television', 'tele', 'vis', 'ion', '멀리(tele) 보기(vis) → 텔레비전'),
  ('telephone', 'tele', 'phon', 'e', '멀리(tele) 소리(phon) → 전화', 'x'),
  ('phone', '', 'phon', 'e', 'telephone 의 줄임 — phon(소리)'),
 ]),
 ('phon', 'G', 'sound', '소리', ['phon'], [
  ('phone', '', 'phon', 'e', '소리 → 전화'),
  ('telephone', 'tele', 'phon', 'e', '멀리(tele) 소리 → 전화', 'x'),
  ('microphone', 'micro', 'phon', 'e', '작은(micro) 소리를 키우는 → 마이크', 'x'),
  ('symphony', 'sym', 'phon', 'y', '함께(sym) 소리 → 교향곡', 'x'),
 ]),
 ('photo', 'G', 'light', '빛', ['photo'], [
  ('photo', '', 'photo', '', '빛으로 그린 것 → 사진'),
  ('photograph', 'photo', 'graph', '', '빛(photo)으로 그림(graph) → 사진', 'x'),
 ]),
 ('poli', 'G', 'city', '도시', ['poli', 'polit'], [
  ('police', '', 'poli', 'ce', '도시의 질서 → 경찰'),
  ('policy', '', 'poli', 'cy', '도시 다스림 → 정책'),
  ('political', '', 'polit', 'ical', '정치의'),
  ('politics', '', 'polit', 'ics', '도시(polis) 일 → 정치'),
  ('metropolis', 'metro', 'poli', 's', '어머니(metro) 도시 → 대도시', 'x'),
 ]),
 ('dem', 'G', 'people', '민중', ['dem'], [
  ('democratic', 'demo', 'crat', 'ic', '민중(demo)이 다스리는(crat) → 민주적인'),
  ('democracy', 'demo', 'crac', 'y', '민주주의', 'x'),
  ('epidemic', 'epi', 'dem', 'ic', '민중 위에(epi) 퍼진 → 유행병', 'x'),
 ]),
 ('techn', 'G', 'art, skill', '기술', ['techn'], [
  ('technology', '', 'techn', 'ology', '기술(techne)의 학문(log) → 기술'),
  ('technical', '', 'techn', 'ical', '기술의'),
  ('technique', '', 'techn', 'ique', '기법', 'x'),
 ]),
 ('cycl', 'G', 'circle', '원', ['cycl'], [
  ('cycle', '', 'cycl', 'e', '원 → 주기·자전거'),
  ('bicycle', 'bi', 'cycl', 'e', '두(bi) 바퀴 → 자전거', 'x'),
  ('recycle', 're', 'cycl', 'e', '다시(re) 돌리다 → 재활용하다', 'x'),
 ]),
 ('phys', 'G', 'nature, body', '자연·몸', ['phys'], [
  ('physical', '', 'phys', 'ical', '몸의·물리적인'),
  ('physics', '', 'phys', 'ics', '자연의 학문 → 물리학', 'x'),
 ]),
 ('medi', 'L', 'middle', '가운데', ['medi'], [
  ('media', '', 'medi', 'a', '가운데에서 전하는 것 → 매체'),
  ('medium', '', 'medi', 'um', '가운데 → 중간·매체'),
  ('immediately', 'im', 'medi', 'ately', '가운데 끼는 것 없이(in) → 즉시'),
  ('medical', '', 'medic', 'al', '치료하는(medicus) → 의학의 — 모양만 닮은 다른 뿌리'),
  ('medicine', '', 'medic', 'ine', '치료 → 의학·약 — medicus 에서'),
 ]),
 ('popul', 'L', 'people', '사람들', ['popul', 'publ'], [
  ('population', '', 'popul', 'ation', '사람 수 → 인구'),
  ('popular', '', 'popul', 'ar', '사람들의 → 인기 있는'),
  ('public', '', 'publ', 'ic', '사람들의 → 공공의'),
  ('publish', '', 'publ', 'ish', '사람들에게 내놓다 → 출판하다'),
  ('republic', 're', 'publ', 'ic', '사람들의 것(res publica) → 공화국'),
  ('people', '', 'peopl', 'e', 'populus 가 프랑스어를 거쳐 → 사람들'),
 ]),
 ('soci', 'L', 'companion', '동료', ['soci'], [
  ('social', '', 'soci', 'al', '동료들의 → 사회적인'),
  ('society', '', 'soci', 'ety', '동료들의 모임 → 사회'),
  ('association', 'as', 'soci', 'ation', '~에(ad) 동료로 묶음 → 협회'),
  ('associated', 'as', 'soci', 'ated', '연관된'),
 ]),
 ('spir', 'L', 'breathe', '숨 쉬다', ['spir'], [
  ('spirit', '', 'spir', 'it', '숨 → 정신·영혼'),
  ('inspired', 'in', 'spir', 'ed', '안으로(in) 숨을 불어 넣은 → 영감을 받은'),
  ('expire', 'ex', 'pir', 'e', '숨을 밖으로(ex+spir, s 가 빠짐) → 만료되다', 'x'),
 ]),
 ('loc', 'L', 'place', '장소', ['loc'], [
  ('local', '', 'loc', 'al', '그 장소의 → 지역의'),
  ('location', '', 'loc', 'ation', '장소 → 위치'),
  ('located', '', 'loc', 'ated', '위치한'),
  ('allocate', 'al', 'loc', 'ate', '~에(ad) 자리를 두다 → 배분하다', 'x'),
 ]),
 ('mod', 'L', 'measure, manner', '척도·방식', ['mod'], [
  ('model', '', 'mod', 'el', '작은 척도 → 모형·모델'),
  ('modern', '', 'mod', 'ern', '지금 방식(modo)의 → 현대의'),
  ('mode', '', 'mod', 'e', '방식'),
  ('modify', '', 'mod', 'ify', '척도에 맞게 → 수정하다', 'x'),
 ]),
 ('ord', 'L', 'order, row', '차례', ['ord'], [
  ('order', '', 'ord', 'er', '차례 → 순서·주문·명령'),
  ('ordered', '', 'ord', 'ered', '주문했다'),
  ('border', 'b', 'ord', 'er', '가장자리(bord) → 국경 — 모양만 닮은 다른 뿌리'),
  ('ordinary', '', 'ord', 'inary', '차례대로의 → 평범한', 'x'),
 ]),
 ('val', 'L', 'strong, worth', '힘·가치', ['val'], [
  ('value', '', 'val', 'ue', '가치'),
  ('valley', '', 'vall', 'ey', '골짜기(vallis) — 모양만 닮은 다른 뿌리'),
  ('valid', '', 'val', 'id', '힘 있는 → 유효한', 'x'),
  ('evaluate', 'e', 'val', 'uate', '가치를 밖으로(e) 끌어내다 → 평가하다', 'x'),
 ]),
 ('fid', 'L', 'trust', '믿다', ['fid', 'fai', 'fed'], [
  ('faith', '', 'fai', 'th', '믿음'),
  ('confidence', 'con', 'fid', 'ence', '완전히(con) 믿음 → 자신감'),
  ('federal', '', 'fed', 'eral', '믿음으로 맺은(foedus) → 연방의'),
  ('fair', '', 'fai', 'r', '아름다운(fæger) — 영어 고유어, 모양만 닮음'),
 ]),
 ('lib', 'L', 'free; book', '자유·책', ['lib'], [
  ('liberal', '', 'lib', 'eral', '자유로운(liber) → 자유주의의'),
  ('library', '', 'lib', 'rary', '책(liber) 두는 곳 → 도서관'),
  ('liberty', '', 'lib', 'erty', '자유', 'x'),
 ]),
 ('lit', 'L', 'letter', '글자', ['lit'], [
  ('literally', '', 'lit', 'erally', '글자 그대로 → 말 그대로'),
  ('literature', '', 'lit', 'erature', '글자로 쓴 것 → 문학'),
  ('little', '', 'lit', 'tle', '영어 고유어 — 모양만 닮음'),
 ]),
 ('min', 'L', 'small; project', '작은·내밀다', ['min'], [
  ('minute', '', 'min', 'ute', '작게 나눈 것 → 분(分)'),
  ('minister', '', 'min', 'ister', '작은 자 → 섬기는 자 → 장관'),
  ('ministry', '', 'min', 'istry', '부(部)'),
  ('administration', 'ad', 'min', 'istration', '~에(ad) 섬김 → 행정'),
  ('minor', '', 'min', 'or', '더 작은 → 사소한'),
  ('minimum', '', 'min', 'imum', '가장 작은 → 최소'),
  ('criminal', '', 'crimin', 'al', '죄(crimen)의 → 범죄자 — 모양만 닮음'),
 ]),
 ('ann', 'L', 'year', '해(年)', ['ann', 'enn'], [
  ('annual', '', 'ann', 'ual', '해마다의 → 연간'),
  ('anniversary', 'anni', 'vers', 'ary', '해(ann)가 돌아옴(vert) → 기념일', 'x'),
  ('announced', 'an', 'nounc', 'ed', '~에(ad) 알리다(nuntiare) → 발표했다 — 모양만 닮음'),
 ]),
 ('corp', 'L', 'body', '몸', ['corp'], [
  ('corporate', '', 'corp', 'orate', '한 몸이 된 → 기업의'),
  ('corporation', '', 'corp', 'oration', '한 몸으로 묶인 것 → 법인·기업'),
  ('corps', '', 'corp', 's', '한 몸 → 군단·단(團)', 'x'),
 ]),
 ('cord', 'L', 'heart', '마음', ['cord', 'cour'], [
  ('record', 're', 'cord', '', '다시(re) 마음에 새김 → 기록'),
  ('according', 'ac', 'cord', 'ing', '~에(ad) 마음을 맞춤 → ~에 따라'),
  ('court', '', 'cour', 't', '울타리 친 마당(cohors) → 법원·궁정 — 모양만 닮은 다른 뿌리'),
  ('courage', '', 'cour', 'age', '마음에서 나오는 것 → 용기', 'x'),
 ]),
 ('clud', 'L', 'close', '닫다', ['clud', 'clus', 'clos'], [
  ('close', '', 'clos', 'e', '닫다·가까운'),
  ('closed', '', 'clos', 'ed', '닫힌'),
  ('include', 'in', 'clud', 'e', '안에(in) 닫아 넣다 → 포함하다'),
  ('including', 'in', 'clud', 'ing', '~을 포함하여'),
  ('exclude', 'ex', 'clud', 'e', '밖으로(ex) 닫아 내다 → 제외하다', 'x'),
  ('conclusion', 'con', 'clus', 'ion', '완전히(con) 닫음 → 결론', 'x'),
 ]),
 ('mem_mind', 'L', 'mind', '마음(ment)', ['ment'], [
  ('mental', '', 'ment', 'al', '마음의 → 정신의'),
  ('mention', '', 'ment', 'ion', '마음에 떠올려 말함 → 언급하다'),
  ('comment', 'com', 'ment', '', '마음속 생각을 함께(com) 꺼냄 → 논평'),
  ('remind', 're', 'mind', '', '다시(re) 마음에 → 떠올리게 하다', 'x'),
 ]),
 ('oper', 'L', 'work', '일', ['oper'], [
  ('operation', '', 'oper', 'ation', '일함 → 작업·수술'),
  ('operating', '', 'oper', 'ating', '작동하는'),
  ('proper', 'pro', 'per', '', '자기 것(proprius) → 적절한 — 모양만 닮은 다른 뿌리'),
  ('property', 'pro', 'per', 'ty', '자기 것 → 재산 — proprius 에서'),
  ('cooperate', 'co', 'oper', 'ate', '함께(co) 일하다 → 협력하다', 'x'),
 ]),
 ('test', 'L', 'witness', '증인', ['test'], [
  ('test', '', 'test', '', '증인 세워 밝힘 → 시험'),
  ('contest', 'con', 'test', '', '함께(con) 증인을 불러 다툼 → 대회', 'x'),
  ('protest', 'pro', 'test', '', '앞에서(pro) 증언하다 → 항의하다', 'x'),
 ]),
 ('text', 'L', 'weave', '짜다', ['text'], [
  ('text', '', 'text', '', '짜 놓은 글 → 본문·문자'),
  ('context', 'con', 'text', '', '함께(con) 짜인 것 → 맥락'),
  ('textile', '', 'text', 'ile', '짠 것 → 직물', 'x'),
 ]),
 ('trib', 'L', 'give, assign', '주다·나누다', ['trib'], [
  ('distribution', 'dis', 'trib', 'ution', '따로따로(dis) 줌 → 분배·유통'),
  ('contribute', 'con', 'trib', 'ute', '함께(con) 주다 → 기여하다', 'x'),
  ('tribute', '', 'trib', 'ute', '바치는 것 → 공물·찬사', 'x'),
 ]),
 ('vol', 'L', 'roll; will', '굴리다·뜻', ['volv', 'volu', 'vol'], [
  ('involved', 'in', 'volv', 'ed', '안으로(in) 굴려 넣은 → 관련된'),
  ('volume', '', 'volu', 'me', '둘둘 굴려 만 책 → 권·부피·음량'),
  ('volunteer', '', 'vol', 'unteer', '스스로 뜻(voluntas)한 사람 → 자원봉사자 — 「뜻」 뿌리', 'x'),
  ('revolution', 're', 'volu', 'tion', '되(re) 굴림 → 혁명', 'x'),
 ]),
 ('sum', 'L', 'take', '취하다', ['sum', 'sumpt'], [
  ('summer', '', 'sum', 'mer', '영어 고유어(sumor) — 모양만 닮음'),
  ('assume', 'as', 'sum', 'e', '~에(ad) 취하다 → 가정하다', 'x'),
  ('consume', 'con', 'sum', 'e', '다(con) 취하다 → 소비하다', 'x'),
 ]),
 ('aud', 'L', 'hear', '듣다', ['aud'], [
  ('audience', '', 'aud', 'ience', '듣는 사람들 → 청중'),
  ('audio', '', 'aud', 'io', '소리', 'x'),
  ('audition', '', 'aud', 'ition', '들어 보기 → 오디션', 'x'),
 ]),
 ('cred', 'L', 'believe', '믿다', ['cred'], [
  ('credit', '', 'cred', 'it', '믿고 맡김 → 신용·학점'),
  ('incredible', 'in', 'cred', 'ible', '믿을(cred) 수 없는(in) → 놀라운'),
  ('credible', '', 'cred', 'ible', '믿을 만한', 'x'),
 ]),
 ('urb', 'L', 'city', '도시', ['urb'], [
  ('urban', '', 'urb', 'an', '도시의'),
  ('suburb', 'sub', 'urb', '', '도시 아래·곁(sub) → 교외', 'x'),
 ]),
 ('vinc', 'L', 'conquer', '이기다', ['vinc', 'vict'], [
  ('victory', '', 'vict', 'ory', '이김 → 승리'),
  ('convince', 'con', 'vinc', 'e', '완전히(con) 이겨 넘기다 → 설득하다', 'x'),
 ]),
 ('sim', 'L', 'same, together', '같은·함께', ['simil', 'sembl', 'sim'], [
  ('similar', '', 'simil', 'ar', '같은 → 비슷한'),
  ('assembly', 'as', 'sembl', 'y', '~로(ad) 함께 모임 → 집회·조립'),
  ('simple', '', 'sim', 'ple', '한 번(sim) 접힌(ply) → 단순한'),
  ('resemble', 're', 'sembl', 'e', '다시(re) 같아 보이다 → 닮다', 'x'),
 ]),
 ('temp', 'L', 'time; moderate', '때·알맞게 하다', ['temp', 'tempor'], [
  ('temperature', '', 'temper', 'ature', '알맞게 섞인 정도 → 온도'),
  ('attempt', 'at', 'tempt', '', '~을(ad) 시험해 보다(temptare) → 시도 — 모양만 닮은 다른 뿌리'),
  ('temporary', '', 'tempor', 'ary', '한때의 → 임시의', 'x'),
 ]),
 ('ped', 'L', 'foot', '발', ['ped'], [
  ('pedestrian', '', 'ped', 'estrian', '발로 가는 사람 → 보행자', 'x'),
  ('pedal', '', 'ped', 'al', '발로 밟는 것 → 페달', 'x'),
  ('expedition', 'ex', 'ped', 'ition', '발을 밖으로(ex) 빼내 떠남 → 원정', 'x'),
 ]),
 ('aqua', 'L', 'water', '물', ['aqu'], [
  ('aquarium', '', 'aqu', 'arium', '물 담는 곳 → 수족관', 'x'),
 ]),
 ('bio', 'G', 'life', '생명', ['bio'], [
  ('biology', '', 'bio', 'logy', '생명의 학문 → 생물학', 'x'),
  ('biography', '', 'bio', 'graphy', '삶을 쓴 것 → 전기', 'x'),
 ]),
 ('auto', 'G', 'self', '스스로', ['auto'], [
  ('automatic', '', 'auto', 'matic', '스스로 움직이는 → 자동의', 'x'),
  ('autograph', '', 'auto', 'graph', '스스로 쓴 것 → 서명', 'x'),
 ]),
 ('chron', 'G', 'time', '시간', ['chron'], [
  ('chronic', '', 'chron', 'ic', '오랜 시간의 → 만성의', 'x'),
  ('synchronize', 'syn', 'chron', 'ize', '같은(syn) 시간에 맞추다 → 동기화하다', 'x'),
 ]),
 ('geo', 'G', 'earth', '땅', ['geo'], [
  ('geography', '', 'geo', 'graphy', '땅을 그림 → 지리', 'x'),
  ('geology', '', 'geo', 'logy', '땅의 학문 → 지질학', 'x'),
 ]),
 ('micro', 'G', 'small', '작은', ['micro'], [
  ('microwave', '', 'micro', 'wave', '작은 파동 → 전자레인지', 'x'),
  ('microscope', '', 'micro', 'scope', '작은 것을 보는(scope) → 현미경', 'x'),
 ]),
 ('psych', 'G', 'mind', '정신', ['psych'], [
  ('psychology', '', 'psych', 'ology', '정신의 학문 → 심리학', 'x'),
 ]),
 ('hydr', 'G', 'water', '물', ['hydr'], [
  ('hydrogen', '', 'hydr', 'ogen', '물을 낳는(gen) → 수소', 'x'),
 ]),
 ('path', 'G', 'feeling, suffering', '느낌·고통', ['path'], [
  ('path', '', 'path', '', '영어 고유어(길) — 모양만 닮음'),
  ('sympathy', 'sym', 'path', 'y', '함께(sym) 느낌 → 동정', 'x'),
  ('empathy', 'em', 'path', 'y', '안으로(en) 들어가 느낌 → 공감', 'x'),
 ]),
]

KO_PRE = PREFIX


def lookalike(hint):
    """닮은꼴 — 어근이 같아 보이지만 다른 뿌리. 힌트에 「모양만 닮음」·「사촌」·「고유어」·「다른 뿌리」가 있거나, 「 — 」 뒤 설명이 「…에서」·「…뿌리」로 끝나면."""
    return any(k in hint for k in ('모양만 닮', '사촌', '고유어', '다른 뿌리')) or bool(re.search(r' — [^→]*(에서|뿌리)$', hint))


def main():
    words = {}
    for r in csv.DictReader(open(ROOT / 'assets/data/words/en_words.csv', encoding='utf-8')):
        words.setdefault(r['word'].lower(), r)
    out = []
    used = set(); errs = []
    for root, origin, meaning, ko, forms, members in R:
        ws = []
        for m in members:
            w, pre, core, suf, hint = m[:5]
            outside = len(m) > 5 and m[5] == 'x'
            e = None
            for cand in (w, w + 's', w + 'd', w + 'ed', w + 'es', w[:-1] + 'ed', w[:-1] + 'ing', w + 'ing', w + 'ment', w + 'ments'):  # 단어장은 표면형이라 굴절형으로도 찾는다
                if cand in words:
                    e = words[cand]; break
            if not e and not outside:
                errs.append(f'{root}: {w} 가 단어장에 없음 — 밖 낱말이면 x 표시'); continue
            if e and outside:
                outside = False  # 단어장에 있으면 안 낱말로
            if (pre + core + suf).replace("'", '') != w.replace("'", ''):
                errs.append(f'{root}: {w} 조각 {pre}+{core}+{suf}'); continue
            ws.append({'w': w, 'parts': [pre, core, suf], 'hint': hint, 'rank': int(e['rank']) if e else 0, 'level': e['level'] if e else '',
                       'ko': e['ko'] if e else '', 'pos': e['pos'] if e else '', 'pre': KO_PRE.get(pre, ''), 'x': outside, 'lw': e['word'] if e else '', 'l': lookalike(hint)})
            if e:
                used.add(w)
        ws.sort(key=lambda x: (x['x'], x['rank'] or 99999))
        inside = [x for x in ws if not x['x']]
        out.append({'root': root.split('_')[0] if '_' in root else root, 'key': root, 'origin': origin, 'meaning': meaning, 'ko': ko, 'forms': forms,
                    'best': inside[0]['rank'] if inside else 99999, 'level': inside[0]['level'] if inside else 'X', 'words': ws})
    if errs:
        raise SystemExit('\n'.join(errs))
    out.sort(key=lambda r: r['best'])
    d = ROOT / 'assets/data/roots'; d.mkdir(parents=True, exist_ok=True)
    json.dump({'_meta': '라틴·그리스 어근 단어 패밀리 — 뜻과 분해는 tools/roots_en.py 에 직접 씀. x = 단어장(2,494어) 밖 낱말. level = 가족 중 가장 흔한 낱말의 절벽 구간.',
               'prefix': KO_PRE, 'roots': out}, open(d / 'roots_en.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    tot = sum(len(r['words']) for r in out)
    from collections import Counter
    print(f'어근 {len(out)} · 낱말 {tot}(단어장 안 {len(used)}, 밖 {tot - len(used)}) · 구간 {dict(Counter(r["level"] for r in out))}')


if __name__ == '__main__':
    main()
