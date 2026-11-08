import 'package:flutter/material.dart';

import '../core/app_flavor.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

/// 라이선스 — 앱 안 그림 자료 출처 + 오픈소스 라이선스(공통 프롬프터 §5-3 "그림 라이선스 표기는 앱 안 라이선스 화면에").
class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  /// 그림 자료 출처(출시용 그림이 들어오면 여기에 적는다). 조음 위치 그림은 임시 그림이라 출시 전 교체 — 표기하지 않는다(사용자 지시 2026-11-08).
  static const List<(String, String, String, String)> _items = [];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text(tr('라이선스'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (_items.isNotEmpty) ...[
            Text(tr('그림 자료'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
            const SizedBox(height: 8),
          ],
          for (final it in _items)
            Card(
              elevation: 0,
              color: AppColors.washiDeep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.line)),
              child: ListTile(
                title: Text(tr(it.$1), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
                subtitle: Text('${it.$2}\n${it.$3} · ${tr(it.$4)}', style: const TextStyle(fontSize: 12, height: 1.4)),
                isThreeLine: true,
              ),
            ),
          const SizedBox(height: 8),
          Text(tr('단어 그림·장면 그림·캐릭터·회화·뜻풀이는 이 앱이 직접 만든 자료입니다.'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(context: context, applicationName: AppFlavor.current.nameKo),
            icon: const Icon(Icons.description_outlined),
            label: Text(tr('오픈소스 라이선스')),
          ),
        ]),
      );
}
