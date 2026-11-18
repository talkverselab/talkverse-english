=== r0_work_a1
title: 첫 출근 문
emoji: 🚪
scene: 첫 출근, 문 앞에서 카드가 안 열려 경비원을 부르는데 문은 당기는 문이었다
where: 사무실 건물 입구
goal: 도움 청하기
kind: short
register: polite
B: Guard
twist: 6 chaos
expr: excuse me | one sec
--
A | Excuse me. Card won't work. | 저기요. 카드가 안 돼요. | excuse me = 저기요 | emo=polite
B | New here? Let me help. | 신입이세요? 도와드릴게요. | let me help = 도와드릴게요 | emo=polite
A | Yes, first day. Thanks. | 네, 첫날이에요. 고마워요. | first day = 첫날 | emo=polite
B | One sec. I'll check. | 잠깐만요. 볼게요. | one sec = 잠깐만 | emo=neutral
B | Try it one more time. | 한 번 더 해보세요. | one more = 한 번 더 | emo=neutral
B | Door says "pull" there. | 문에 「당기시오」라고 써 있어요. | says pull = 당기시오 | emo=amused
A | Oh. Hi, door. | 아. 안녕, 문아. | hi door = 안녕 문 | emo=amused
