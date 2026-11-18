=== r1_work_a2
title: 시급 이야기
emoji: 💵
scene: 서점 아르바이트 면접에서 사장이 시급을 물어보는데, 학습자가 너무 낮게 불러 사장이 올려 준다
where: 동네 서점
goal: 면접에서 짧게 답하기
kind: short
register: polite
B: Owner
twist: 6 ignore
expr: sounds good | are you sure | i think so | of course
--
B | Do you like books? | 책 좋아하세요? | books = 책 | emo=polite
A | Of course. I read every night. | 물론이죠. 매일 밤 읽어요. | of course = 물론이죠 | emo=polite
B | Can you work on weekends? | 주말에 일할 수 있어요? | weekends = 주말 | emo=polite
A | I think so. Yes. | 그럴 것 같아요. 네. | i think so = 그럴 것 같아요 | emo=neutral
B | What pay do you want? | 시급 얼마 원하세요? | pay = 시급 | emo=polite
A | Five dollars an hour? | 시간당 5달러요? | five = 다섯 | emo=neutral
B | Are you sure? That's illegal. Eighteen. | 확실해요? 그건 불법이에요. 18달러요. | are you sure = 확실해요 | emo=surprised
A | Sounds good. I'll take it. | 좋아요. 할게요! | sounds good = 좋아요 | emo=cheerful
