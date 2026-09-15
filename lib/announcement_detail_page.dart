import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'announcement_model.dart'; // 作成したモデルをインポート
import 'webview_page.dart';
import 'app_colors.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.announce(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ詳細'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(announcement.timestamp),
                  style: TextStyle(fontSize: 12, color: palette.text),
                ),
              ),
              const Divider(height: 24),
              // microCMSのリッチエディタ項目はHTML文字列で返ってくるためHtmlWidgetで描画
              HtmlWidget(
                announcement.content,
                onTapUrl: (url) {
                  openUrl(context, url);
                  return true;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}