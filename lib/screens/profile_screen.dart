import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/learner_prefs.dart';
import '../widgets/achievement_desk.dart';
import '../widgets/english_decor.dart';
import 'update_screen.dart';

/// 「나」 — 성과 데스크 + 학습자 프로필(이름·성별) + 앱 업데이트·정보.
/// 계정(Talkverse ID 로그인·이용권)은 사용자가 「착수」 한 뒤 붙인다(공통 프롬프터 §11).
class ProfileScreen extends StatefulWidget {
  final bool embedded; // 「나」 탭 안(앱바·스크롤 없이, 바깥 ListView 에 들어감)
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version} (${p.buildNumber})');
    });
  }

  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('학습 기록 초기화')),
        content: Text(tr('편 완주·그림 카드 기록을 지웁니다. 되돌릴 수 없어요.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('취소'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('지우기'))),
        ],
      ),
    );
    if (ok != true) return;
    final p = await SharedPreferences.getInstance();
    await p.remove('achievements_v1');
    await p.remove('dialogue_last');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('기록을 지웠어요. 앱을 다시 열면 반영됩니다.'))));
    }
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, maxLength: 20, autofocus: true, decoration: InputDecoration(hintText: tr('회화 속 「나」로 나와요'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v == null) return;
    await LearnerPrefs.setName(v);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _SectionTitle(tr('성과')),
      const SizedBox(height: 8),
      const AchievementDesk(),
      const SizedBox(height: 18),
      _SectionTitle(tr('학습자 프로필')),
      const SizedBox(height: 8),
      _SettingsGroup(items: [
        _SettingItem(
          icon: Icons.badge_outlined,
          title: tr('이름'),
          subtitle: LearnerPrefs.name.value.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [LearnerPrefs.name.value]) : tr('없음 — 회화에서 「○○」로 보여요'),
          onTap: _editName,
        ),
        _SettingItem(
          icon: LearnerPrefs.isFemale ? Icons.face_3 : Icons.face,
          title: tr('성별 (「나」의 목소리 · 장면 그림)'),
          subtitle: LearnerPrefs.isFemale ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'),
          onTap: () async {
            await LearnerPrefs.setGender(LearnerPrefs.isFemale ? 'male' : 'female');
            if (mounted) setState(() {});
          },
        ),
      ]),
      const SizedBox(height: 18),
      _SectionTitle(tr('앱')),
      const SizedBox(height: 8),
      const UpdateEntryTile(),
      _SettingsGroup(items: [
        _SettingItem(icon: Icons.volume_up, title: tr('목소리'), subtitle: tr('기기 영어(미국) 목소리 · 남/여 구분')),
        _SettingItem(icon: Icons.restart_alt, title: tr('학습 기록 초기화'), subtitle: tr('편 완주 · 그림 카드 기록 삭제'), onTap: _resetProgress),
        _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: _version.isEmpty ? '—' : _version),
        _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('영어유니버스 · 2026')),
      ]),
      const SizedBox(height: 20),
      const BrushDivider(),
      const SizedBox(height: 32),
    ];
    if (widget.embedded) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('나'))),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.sumi, letterSpacing: 0.5));
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    // ListTile 은 가장 가까운 Material 에 잉크를 그리므로 색 있는 Container 안에서는 Material 로 감싼다
    return Material(
      color: AppColors.washi,
      shape: Border.all(color: AppColors.kin.withValues(alpha: 0.5)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.beni.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.beni, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.beni, size: 18),
              ),
              title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sumi)),
              subtitle: Text(items[i].subtitle, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
              trailing: items[i].onTap != null
                  ? const Icon(Icons.chevron_right, color: AppColors.beni, size: 18)
                  : null,
            ),
            if (i < items.length - 1) Container(height: 0.5, color: AppColors.kin.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
