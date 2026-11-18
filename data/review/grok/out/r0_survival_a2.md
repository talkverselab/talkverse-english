=== r0_survival_a2
title: 버스 안 탈 건데요
emoji: 🚌
scene: 정류장에서 시간을 물었을 뿐인데 기사는 탈 거냐고 계속 묻는다
where: 버스 정류장
goal: 시간 묻기
kind: survival
register: polite
B: Driver
twist: 7 reveal
expr: excuse me | no thanks
--
A | Excuse me, the time? | 저기요, 지금 몇 시예요? | excuse me = 저기요 | emo=polite
B | You getting on? | 타실 거예요? | getting on = 타다 | emo=neutral
A | No thanks, just time. | 아뇨 괜찮아요, 시간만요. | no thanks = 괜찮아요 | emo=polite
B | Sure? It's pretty late. | 확실해요? 꽤 늦었는데요. | pretty late = 꽤 늦다 | emo=neutral
A | I only want the time. | 시간만 알고 싶어요. | only want = 그냥 알고 싶다 | emo=neutral
B | Dark now, last bus. | 지금 어두워요, 막차예요. | last bus = 막차 | emo=neutral
A | Oh no, totally dark. | 어떡해, 완전 깜깜하네. | totally dark = 완전 깜깜 | emo=surprised
B | Get on, I'll wait. | 타요, 기다릴게요. | get on = 타다 | emo=polite
