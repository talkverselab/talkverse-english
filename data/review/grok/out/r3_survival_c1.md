=== r3_survival_c1
title: 환불은 영수증이 있어야죠
emoji: 🧾
scene: 사이즈가 안 맞는 재킷을 반품하러 갔는데 영수증이 없고, 알고 보니 재킷이 다른 가게 것이다
where: 동네 옷 가게 계산대
goal: 반품·교환 요청하고 조건 묻기
kind: survival
register: polite
B: Clerk
twist: 10 chaos
expr: just to confirm | i could be wrong | fair enough
--
A | Hi, I'd like to return this jacket. It's way too big on me. | 안녕하세요, 이 재킷 반품하고 싶어요. 저한테 너무 커서요. | return = 반품하다 | emo=polite
B | Do you have the receipt? | 영수증 있으세요? | receipt = 영수증 | emo=polite
A | I think I lost it. | 잃어버린 것 같아요. | lost = 잃어버리다 | emo=neutral
B | We usually need it for returns. | 보통 반품엔 필요해요. | usually = 보통 | emo=polite
A | Can I exchange it instead? | 교환은 될까요? | exchange = 교환 | emo=polite
B | Maybe, if we can find the sale. | 판매 기록 찾으면 될 수도요. | sale = 판매 | emo=polite
A | Really? I could be wrong, but I'm sure it was here. | 정말요? 제가 틀릴 수도 있지만, 분명히 여기였어요. | i could be wrong = 틀릴 수도 있지만 | emo=neutral
B | Just to confirm, you bought it at this location? | 확인차 여쭤요, 이 지점에서 사신 거죠? | just to confirm = 확인차 | emo=polite
A | Yeah, last week I think. | 네, 지난주인 것 같아요. | last week = 지난주 | emo=neutral
B | Hold on… that tag is from the store next door. | 저기요… 그 태그, 옆 가게 거예요. | tag = 태그 | emo=surprised
A | What? Are you serious? | 뭐요? 진짜요? | serious = 진짜 | emo=surprised
B | Yes, different brand too. | 네, 브랜드도 달라요. | brand = 브랜드 | emo=neutral
A | Fair enough. So where's their entrance? | 그럴 만하네요. 그럼 그 가게 문은 어디예요? | fair enough = 그럴 만하네요 | emo=neutral
B | Out and to the left. Take the jacket, it's not ours. | 나가서 왼쪽이요. 재킷은 가져가세요, 저희 거 아니에요. | left = 왼쪽 | emo=polite
