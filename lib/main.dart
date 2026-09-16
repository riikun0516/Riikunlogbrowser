import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:io';

import 'rss_list_page.dart'; //
import 'podcast_list_page.dart'; //
import 'privacy_policy_page.dart'; //
import 'webview_page.dart'; //
import 'announcements_page.dart'; //
import 'app_colors.dart';
import 'menu_card.dart';

import 'package:upgrader/upgrader.dart'; //

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //
  if (Platform.isLinux) {
    // Snap環境では自動検出が失敗するため、実際に同梱しているパスを明示的に指定する
    MediaKit.ensureInitialized(
      libmpv: '${Platform.environment['SNAP'] ?? ''}/usr/lib/x86_64-linux-gnu/libmpv.so.2',
    );
  } else {
    MediaKit.ensureInitialized(); //
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String fontFamilyName = 'LINESeedJP';

    return MaterialApp(
      title: 'りーろぐブラウザ', //
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed), //
        useMaterial3: true, //
        fontFamily: fontFamilyName,
        textTheme:
            Theme.of(context).textTheme.apply(fontFamily: fontFamilyName),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed, //
          brightness: Brightness.dark, //
        ),
        useMaterial3: true, //
        fontFamily: fontFamilyName,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamilyName),
      ),
      themeMode: ThemeMode.system, //
      home: const HomePage(), //
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      //
      upgrader: Upgrader(
        messages: UpgraderMessages(code: 'ja'), //
      ),
      child: PopScope(
        //
        canPop: false, //
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;

          final bool shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('アプリを終了しますか？'), //
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false), //
                      child: const Text('いいえ'), //
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true), //
                      child: const Text('はい'), //
                    ),
                  ],
                ),
              ) ??
              false;

          // ★修正：context.mounted チェックを入れることで、ダイアログ中に画面が消えた場合のクラッシュを防ぐ
          if (shouldPop && context.mounted) {
            exit(0);
          }
        },
        child: SafeArea(
          top: false, //
          child: Scaffold(
            appBar: AppBar(
              title: const Text('りーろぐブラウザ'), //
              actions: [
                PopupMenuButton<String>(
                  //
                  onSelected: (value) {
                    if (value == 'license') {
                      showLicensePage(
                        context: context,
                        applicationName: 'りーろぐブラウザ', //
                        applicationVersion: '2026.04.07-rev0', //
                      );
                    } else if (value == 'privacy') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(), //
                      ));
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                        value: 'license', child: Text('ライセンス')), //
                    const PopupMenuItem<String>(
                        value: 'privacy', child: Text('プライバシーポリシー')), //
                  ],
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0), //
              child: ListView(
                children: [
                  Text(
                    'なにを見ますか?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  MenuCard(
                    title: 'りーろぐ',
                    subtitle: 'ブログ記事を読む',
                    icon: Icons.rss_feed,
                    palette: AppColors.rss(context),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RssListPage(),
                      ));
                    },
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    title: 'RadioStrike',
                    subtitle: 'ポッドキャストを聴く',
                    icon: Icons.headphones,
                    palette: AppColors.podcast(context),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PodcastListPage(),
                      ));
                    },
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    title: 'Webブラウザを開く',
                    subtitle: '内蔵ブラウザでサイトを見る',
                    icon: Icons.public,
                    palette: AppColors.web(context),
                    onTap: () {
                      openUrl(context, 'https://www.google.com');
                    },
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    title: 'お知らせ',
                    subtitle: '最新情報を確認',
                    icon: Icons.campaign,
                    palette: AppColors.announce(context),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AnnouncementsPage(), //
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
