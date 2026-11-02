/// 표시 언어 기능 없음 — 화면 문구는 한국어 그대로(공통 프롬프터 §3).
String tr(String ko) => ko;

/// 보간 문구 — 템플릿의 `{0}`, `{1}`… 자리에 값을 채운다.
String trf(String template, List<Object?> args) {
  var s = template;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}
