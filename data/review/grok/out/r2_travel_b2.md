=== r2_travel_b2
title: 호텔 방이 업그레이드됐는데
emoji: 🏨
scene: 체크인에서 방이 무료 업그레이드됐다는데, 알고 보니 엘리베이터 없는 꼭대기 층이다
where: 작은 호텔 프런트
goal: 체크인 말과 확인 질문
kind: short
register: polite
B: Clerk
twist: 7 reveal
expr: just to confirm | sounds good | that's it
--
A | Hi, I have a reservation under {name}. | 안녕하세요, 예약했어요. {name} 이름으로요. | reservation = 예약 | emo=polite
B | Found it. We upgraded you for free. | 찾았어요. 무료로 업그레이드해 드렸어요. | upgraded = 업그레이드 | emo=polite
A | Really? Sounds good. | 진짜요? 좋네요. | sounds good = 좋네요 | emo=cheerful
B | Top floor, nice view. | 꼭대기 층, 전망 좋아요. | view = 전망 | emo=polite
A | Just to confirm, breakfast is included? | 확인 차, 조식 포함이죠? | just to confirm = 확인 차 | emo=polite
B | Yes, from seven to ten. | 네, 7시부터 10시까지요. | included = 포함 | emo=polite
A | Great. Where's the elevator? | 좋아요. 엘리베이터는 어디예요? | elevator = 엘리베이터 | emo=neutral
B | This hotel doesn't have one. | 이 호텔엔 없어요. | hotel = 호텔 | emo=neutral
A | That's it. So that's the upgrade. | 그거네요. 그게 업그레이드구나. | that's it = 그거네요 | emo=amused
B | Breakfast tastes better after the stairs. | 계단 오르고 먹는 조식이 더 맛있어요. | stairs = 계단 | emo=teasing
