=== r1_travel_a1
title: 창가 자리 부탁
emoji: ✈️
scene: 비행기 체크인에서 창가 자리를 부탁했는데, 직원이 준 자리는 창문이 없는 창가였다
where: 공항 체크인 카운터
goal: 자리 요청하기
kind: survival
register: polite
B: Agent
twist: 6 chaos
expr: can i get | sure | how much | oh no
--
B | Hi. Where to today? | 안녕하세요. 오늘 어디로 가세요? | where to = 어디로 | emo=polite
A | Chicago. Can I get a window? | 시카고요. 창가 자리 주실 수 있어요? | can i get = 주실 수 있어요 | emo=polite
B | Sure. Window, row twelve. | 네. 창가 자리, 12열이요. | sure = 네 | emo=polite
A | Great. How much for the bag? | 좋아요. 짐은 얼마예요? | how much = 얼마 | emo=neutral
B | Twenty dollars. One bag. | 20달러. 가방 하나. | twenty dollars = 20달러 | emo=neutral
A | Oh no. Row twelve has no window. | 아 이런. 12열엔 창문이 없어요. | oh no = 아 이런 | emo=surprised
B | Yeah, it's the wall side. | 네, 벽 쪽이에요. | wall side = 벽 쪽 | emo=neutral
A | So I stare at a wall to Chicago. | 그럼 시카고까지 벽만 보고 가네요. | stare at wall = 벽만 보다 | emo=amused
