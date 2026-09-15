import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'webview_page.dart'; // WebViewPageをインポート
import 'app_colors.dart';

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final DateTime? pubDate;
  final String? htmlContent;

  const ArticleDetailPage({
    super.key,
    required this.title,
    this.pubDate,
    this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.rss(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea( // UIのはみ出しを修正
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              if (pubDate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(pubDate!),
                    style: TextStyle(fontSize: 12, color: palette.text),
                  ),
                ),
              const Divider(height: 24),
              if (htmlContent != null)
                HtmlWidget(
                  htmlContent!,
                  // リンクタップ時の処理を追加
                  onTapUrl: (url) {
                    openUrl(context, url);
                    return true;
                  },
                )
              else
                const Text('本文を読み込めませんでした。'),
            ],
          ),
        ),
      ),
    );
  }
}