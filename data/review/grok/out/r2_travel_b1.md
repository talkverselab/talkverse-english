=== r2_travel_b1
title: 공항 보안검색대의 고추장
emoji: 🛂
scene: 공항 검색대에서 가방 속 소스 병 때문에 걸리고, 직원이 그 소스를 궁금해한다
where: 공항 보안검색대
goal: 검색대 지시 알아듣기
kind: survival
register: polite
B: Officer
twist: 8 chaos
expr: what does that mean | almost | are you kidding
--
B | Is this your bag? Step over here. | 이거 손님 가방이에요? 이쪽으로 오세요. | bag = 가방 | emo=polite
A | Yes, that's mine. | 네, 제 거예요. | mine = 제 것 | emo=polite
B | Open it please. What's this bottle? | 열어 주세요. 이 병 뭐예요? | bottle = 병 | emo=polite
A | Three ounces? What does that mean? | 3온스요? 그게 무슨 뜻이에요? | what does that mean = 무슨 뜻이에요 | emo=neutral
B | Liquids over that size can't go. | 그 크기 넘는 액체는 안 돼요. | liquids = 액체 | emo=polite
A | It's just Korean chili paste. | 그냥 한국 고추장이에요. | chili paste = 고추장 | emo=neutral
B | Still too big for carry-on. | 그래도 기내 반입엔 너무 커요. | carry-on = 기내 반입 | emo=polite
A | Are you kidding? It's almost full. | 농담이죠? 거의 꽉 찼는데. | are you kidding = 농담이죠 | emo=surprised
B | Rules are rules. You can check it. | 규칙은 규칙이에요. 위탁할 수 있어요. | rules = 규칙 | emo=neutral
A | It's great with rice. Enjoy, I guess. | 밥이랑 최고예요. 맛있게 드세요, 뭐. | enjoy = 맛있게 드세요 | emo=amused
