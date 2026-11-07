import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import 'stress_text.dart';

/// 강세 표시 버튼(앱바용) — 영어앱의 「읽기 보조」(일본어앱 후리가나 토글과 같은 자리, 사용자 지시 2026-11-07).
/// 기본 미표시. 표시로 켤 때 스낵바로 한 번 알린다.
class StressToggleAction extends StatelessWidget {
  const StressToggleAction({super.key});

  static Future<void> toggle(BuildContext context) async {
    await StressPrefs.toggle();
    if (StressPrefs.on.value && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(tr('힘들어도 강세 표시를 보지 않고 익혀보세요')),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.sumi,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StressPrefs.on,
      builder: (context, on, _) {
        final color = on ? AppColors.ai : AppColors.muted.withValues(alpha: 0.6);
        return IconButton(
          tooltip: on ? tr('강세 숨기기') : tr('강세 표시'),
          onPressed: () => toggle(context),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: color, width: 1.2), borderRadius: BorderRadius.circular(6)),
            child: Text('강', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color, decoration: on ? null : TextDecoration.lineThrough)),
          ),
        );
      },
    );
  }
}
