=== r0_travel_a2
title: 호텔 방 번호
emoji: 🏨
scene: 호텔 직원이 방 번호를 말했는데 학습자가 숫자를 거꾸로 알아듣는다
where: 호텔 앞 데스크
goal: 숫자 확인하기
kind: survival
register: polite
B: Clerk
twist: 6 slip
expr: say that again | got it
--
B | Your room is fifty-one. | 방은 51호예요. | fifty-one = 51 | emo=polite
A | Fifty-one? Okay. | 51이요? 알겠어요. | fifty-one = 51 | emo=neutral
B | Yes, on the fifth floor. | 네, 5층이에요. | fifth floor = 5층 | emo=neutral
A | Sorry. Say that again. | 죄송해요. 다시 말해 주세요. | say that again = 다시 말해 | emo=polite
B | Room five one. | 방 5 1이에요. | five one = 5 1 | emo=neutral
A | Got it. Fifteen! | 알겠어요. 15호! | got it = 알겠어요 | emo=cheerful
B | I'll walk you there. | 같이 가 드릴게요. | walk you = 같이 가다 | emo=polite
