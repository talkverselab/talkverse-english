import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_flavor.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import 'english_decor.dart';

/// 앱 가족 — 영어·토익·토익스피킹·OPIc 사이 이동(사용자 지시 2026-11-08 "앱 안에서 서로 오갈 수 있어야").
/// 깔려 있으면 그 앱을 열고(URL 스킴), 없으면 설치 안내(Zealot·스토어 주소).
class AppFamilyList extends StatelessWidget {
  const AppFamilyList({super.key});

  static Future<void> open(BuildContext context, AppFlavor app) async {
    final uri = Uri.parse('${app.scheme}://open');
    var ok = false;
    try {
      ok = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(trf('{0} 앱이 아직 설치되지 않았어요. apps.talkverse.uk 에서 받을 수 있어요.', [app.nameKo])),
      action: SnackBarAction(
        label: tr('받기'),
        onPressed: () => launchUrl(Uri.parse('https://apps.talkverse.uk'), mode: LaunchMode.externalApplication),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final app in AppFlavor.others)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(context, app),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    SealStamp(text: _seal(app), size: 40, color: _color(app)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(app.nameKo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                        const SizedBox(height: 2),
                        Text(tr(app.tagline), style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                      ]),
                    ),
                    const Icon(Icons.open_in_new, size: 18, color: AppColors.sumiLight),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  static String _seal(AppFlavor a) => switch (a) { AppFlavor.english => 'E', AppFlavor.toeic => 'T', AppFlavor.toeicSpeaking => 'TS', AppFlavor.opic => 'OP' };
  static Color? _color(AppFlavor a) => switch (a) { AppFlavor.english => null, AppFlavor.toeic => AppColors.matcha, AppFlavor.toeicSpeaking => AppColors.sakuraDeep, AppFlavor.opic => AppColors.kinBright };
}
