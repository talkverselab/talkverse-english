=== r1_survival_s4
title: 약국에서 "Sure"의 값
emoji: 💊
scene: 두통약 하나 사러 갔는데 회원 가입·영수증 질문마다 Sure 라고 했다가 영수증이 1미터가 된다
where: 동네 약국 계산대
goal: 계산대 질문에 고르는 말로 답하기
kind: survival
register: polite
B: Clerk
twist: 6 chaos
expr: sure | just this
--
B | Hi. Just this today? | 안녕하세요. 이것만요? | just this = 이것만 | emo=polite
A | Yes, the headache one. | 네, 두통약 하나요. | headache one = 두통약 하나 | emo=neutral
B | Want to join our rewards? | 리워드 가입하시겠어요? | join rewards = 리워드 가입 | emo=neutral
A | Sure. | 네. | sure = 네 | emo=polite
B | Email receipt or print? | 이메일 영수증 아니면 출력? | email or print = 이메일 아니면 출력 | emo=neutral
A | Sure. | 네. | sure = 네 | emo=neutral
B | Okay, printing everything now. | 알겠어요, 지금 다 출력할게요. | printing everything = 다 출력 | emo=cheerful
A | Wait. This receipt is longer than me. | 잠깐만요. 영수증이 저보다 길어요. | longer than me = 저보다 길다 | emo=surprised
