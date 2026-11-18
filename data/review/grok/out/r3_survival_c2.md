=== r3_survival_c2
title: 약국에서 증상 설명하기
emoji: 💊
scene: 목이 아파서 약국에 갔는데 약사가 묻는 말마다 학습자가 너무 자세하게 대답해서 줄이 길어진다
where: 동네 약국
goal: 증상 말하고 약 고르기
kind: survival
register: polite
B: Pharmacist
twist: 9 ignore
expr: to be honest | it depends | are you sure
--
A | Hi. My throat's been really sore since yesterday. | 안녕하세요. 어제부터 목이 너무 아파요. | throat = 목 | emo=polite
B | Any other symptoms? Fever or cough? | 다른 증상 있어요? 열이나 기침? | symptoms = 증상 | emo=polite
A | No fever. Just hurts when I swallow. | 열은 없어요. 삼킬 때만 아파요. | swallow = 삼키다 | emo=neutral
B | Have you taken anything yet? | 뭐 드신 거 있어요? | taken = 드시다 | emo=polite
A | To be honest, just vitamins. And my roommate's tea. | 솔직히 비타민만요. 그리고 룸메이트 차요. | to be honest = 솔직히 | emo=neutral
B | What kind of tea? It depends what's in it. | 무슨 차요? 뭐가 들었느냐에 따라 달라서요. | it depends = 에 따라 달라서요 | emo=polite
A | Some herbal thing. Smells like flowers. | 허브 같은 거요. 꽃 냄새 나요. | herbal = 허브 | emo=neutral
B | Okay. How long does the pain last? | 알겠어요. 통증은 얼마나 지속돼요? | pain = 통증 | emo=polite
A | Oh, and I sang for three hours at a party last week. | 아, 그리고 지난주에 파티에서 세 시간 노래했어요. | sang = 노래하다 | emo=neutral
B | That might be it. Overuse. | 그게 원인일 수도요. 과사용. | overuse = 과사용 | emo=neutral
A | Are you sure? You didn't ask about singing. | 확실해요? 노래 얘기는 안 물어보셨잖아요. | are you sure = 확실해요 | emo=neutral
B | It's relevant. Rest your voice. | 관련 있어요. 목소리 쉬세요. | relevant = 관련 있는 | emo=polite
A | So no more parties? | 그럼 파티 그만? | parties = 파티 | emo=teasing
B | No ice cream tonight. That's the real medicine. | 오늘 밤엔 아이스크림 금지. 그게 진짜 약이에요. | ice cream = 아이스크림 | emo=amused
