=== r2_life_b2
title: 택배가 옆집에 갔다
emoji: 📦
scene: 택배가 이웃 집 앞에 놓였다는 알림을 받고 찾으러 가는데, 이웃이 이미 열어 봤다
where: 아파트 복도
goal: 이웃에게 부탁하기
kind: short
register: polite
B: Neighbor
twist: 6 chaos
expr: excuse me | long story | not really
--
A | Excuse me. I think my package came here. | 안녕하세요, 실례합니다. 제 택배가 여기로 온 것 같아요. | excuse me = 실례합니다 | emo=polite
B | Oh, the brown box by the door? | 아, 문 앞 갈색 상자요? | box = 상자 | emo=polite
A | Yes, it has my name on it. | 네, 제 이름이 있어요. | name = 이름 | emo=neutral
B | I brought it inside already. | 안으로 들여놨어요. | inside = 안 | emo=polite
A | Thanks. Can I pick it up? | 고마워요. 받아도 될까요? | pick up = 받다 | emo=polite
B | The cat-shaped lamp? | 고양이 모양 램프요? | lamp = 램프 | emo=amused
A | Long story. Not really my style. | 얘기하자면 길어요. 제 취향은 아니에요. | long story = 얘기하자면 길어요 | emo=flustered
B | I already plugged it in. | 이미 꽂아 봤어요. | plugged = 꽂다 | emo=cheerful
A | Wait, you opened the box? | 잠깐, 상자를 열어 보셨어요? | opened = 열다 | emo=surprised
B | It's in my kid's room. Named it Mr. Whiskers. | 애 방에요. 이름도 위스커스 씨로 지었어요. | named = 이름 짓다 | emo=amused
