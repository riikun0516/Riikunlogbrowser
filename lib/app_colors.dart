import 'package:flutter/material.dart';

// UI刷新(スタイルB: ポップ・カラフル)用の配色。
// 機能ごとに色を割り当てる: りーろぐ=紫, RadioStrike=緑, Webブラウザ=珊瑚, お知らせ=桃色。
// ライト/ダークモードそれぞれで見やすい組み合わせを用意している。
class SectionPalette {
  final Color background;
  final Color icon;
  final Color text;

  const SectionPalette({
    required this.background,
    required this.icon,
    required this.text,
  });
}

class AppColors {
  // Material3のシード色(全体のアクセント)
  static const seed = Color(0xFF7F77DD);

  static const _rssLight =
      SectionPalette(background: Color(0xFFEEEDFE), icon: Color(0xFF534AB7), text: Color(0xFF3C3489));
  static const _rssDark =
      SectionPalette(background: Color(0xFF3C3489), icon: Color(0xFFCECBF6), text: Color(0xFFEEEDFE));

  static const _podcastLight =
      SectionPalette(background: Color(0xFFE1F5EE), icon: Color(0xFF0F6E56), text: Color(0xFF085041));
  static const _podcastDark =
      SectionPalette(background: Color(0xFF085041), icon: Color(0xFF9FE1CB), text: Color(0xFFE1F5EE));

  static const _webLight =
      SectionPalette(background: Color(0xFFFAECE7), icon: Color(0xFF993C1D), text: Color(0xFF712B13));
  static const _webDark =
      SectionPalette(background: Color(0xFF712B13), icon: Color(0xFFF5C4B3), text: Color(0xFFFAECE7));

  static const _announceLight =
      SectionPalette(background: Color(0xFFFBEAF0), icon: Color(0xFF993556), text: Color(0xFF72243E));
  static const _announceDark =
      SectionPalette(background: Color(0xFF72243E), icon: Color(0xFFF4C0D1), text: Color(0xFFFBEAF0));

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static SectionPalette rss(BuildContext context) =>
      _isDark(context) ? _rssDark : _rssLight;
  static SectionPalette podcast(BuildContext context) =>
      _isDark(context) ? _podcastDark : _podcastLight;
  static SectionPalette web(BuildContext context) =>
      _isDark(context) ? _webDark : _webLight;
  static SectionPalette announce(BuildContext context) =>
      _isDark(context) ? _announceDark : _announceLight;
}
