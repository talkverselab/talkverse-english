=== r2_survival_b2
title: 셀프 계산대가 나를 의심한다
emoji: 🛒
scene: 마트 셀프 계산대가 바나나 무게 때문에 계속 직원을 부르고, 직원은 학습자 얼굴을 기억한다
where: 동네 마트 셀프 계산대
goal: 기계 안내 말과 직원 부르기
kind: survival
register: mixed
B: Clerk
twist: 7 chaos
expr: hold on | not again | my bad
--
A | Excuse me, unexpected item in the bag area. | 저기요, 죄송한데요. "봉투 칸에 예상치 못한 물건"이래요. | unexpected = 예상치 못한 | emo=polite
B | Hold on. What did you put there? | 네, 잠깐만요. 거기 뭐 올리셨어요? | hold on = 잠깐만요 | emo=polite
A | Just a few bananas. | 바나나 몇 개요. | bananas = 바나나 | emo=neutral
B | Let me check the scale again. | 저울 다시 확인해 볼게요. | scale = 저울 | emo=polite
A | It keeps calling for help. | 계속 도움을 요청해요. | keeps = 계속 | emo=neutral
B | Not again? Did you put a bag on it? | 또요? 가방 올리셨어요? | not again = 또요 | emo=annoyed
A | My bad. That's my backpack. | 제 잘못이에요. 그거 제 배낭이에요. | my bad = 제 잘못이에요 | emo=flustered
B | Oh, I remember your face from yesterday. | 아, 어제 얼굴 기억이 나네요. | remember = 기억하다 | emo=amused
A | Sorry, the bananas were really light. | 죄송해요, 바나나가 너무 가벼워서요. | light = 가벼운 | emo=neutral
B | Next time just come to my line. | 다음엔 그냥 제 줄로 오세요. | next time = 다음엔 | emo=polite
