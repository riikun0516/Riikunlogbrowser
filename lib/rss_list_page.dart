import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'article_detail_page.dart';
import 'portable_text.dart';
import 'app_colors.dart';

// EmdashのAPIレスポンス1件分を表すモデル
class EmdashArticle {
  final String id;
  final String title;
  final DateTime? publishedAt;
  final dynamic body; // Portable Text(List)または単純な文字列を想定
  final String status;

  EmdashArticle({
    required this.id,
    required this.title,
    this.publishedAt,
    this.body,
    required this.status,
  });

  factory EmdashArticle.fromJson(Map<String, dynamic> json) {
    // フィールドの実体は item.data の中にネストされている
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dateStr = json['publishedAt'] ?? json['createdAt'];
    return EmdashArticle(
      id: json['id']?.toString() ?? '',
      title: data['title'] as String? ?? 'タイトルなし',
      publishedAt: dateStr is String ? DateTime.tryParse(dateStr) : null,
      body: data['content'] ?? data['body'],
      status: json['status'] as String? ?? 'draft',
    );
  }
}

class RssListPage extends StatefulWidget {
  const RssListPage({super.key});

  @override
  State<RssListPage> createState() => _RssListPageState();
}


class _RssListPageState extends State<RssListPage> {
  // ▼▼▼ ご自身のEmdashサイトの情報に書き換えてください ▼▼▼
  // サイトのドメイン(末尾にスラッシュは不要)
  static const String _siteBaseUrl = 'https://blog.radiostrike.jp';
  // 記事が入っているコレクション名(管理画面の「Posts」に対応するスラッグ)
  static const String _collection = 'posts';
  // 設定画面で発行した「コンテンツ読み取り」スコープのAPIトークン
  static const String _apiToken = 'ec_pat_kABqQOnGdXgVjMtj1q-ijgJDGhuHer0TNaePuTKQeek';

Uri get _apiUrl => Uri.parse(
        '$_siteBaseUrl/_emdash/api/content/$_collection?limit=50',
      );

  Future<List<EmdashArticle>>? _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = fetchArticles();
  }

  Future<List<EmdashArticle>> fetchArticles() async {
    final response = await http.get(
      _apiUrl,
      headers: {'Authorization': 'Bearer $_apiToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('サーバーエラー: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    // レスポンスの形が複数パターン考えられるため、順番に試す
    // 1. { data: { items: [...] } }  ← 実際の形
    // 2. { data: { entries: [...] } }
    // 3. { entries: [...] } / { items: [...] }
    // 4. [...] (配列がそのまま返る)
    List<dynamic>? rawEntries;

    if (decoded is List) {
      rawEntries = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw Exception('APIエラー: ${decoded['error']}');
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        if (data['items'] is List) {
          rawEntries = data['items'] as List;
        } else if (data['entries'] is List) {
          rawEntries = data['entries'] as List;
        }
      } else if (data is List) {
        rawEntries = data;
      } else if (decoded['items'] is List) {
        rawEntries = decoded['items'] as List;
      } else if (decoded['entries'] is List) {
        rawEntries = decoded['entries'] as List;
      }
    }

    if (rawEntries == null) {
      // どのパターンにも当てはまらなかった場合、実際の形をそのままエラーに出す
      throw Exception('予期しないレスポンス形式です: $decoded');
    }

    final entries = rawEntries.cast<Map<String, dynamic>>();
    final articles = entries
        .map(EmdashArticle.fromJson)
        // 下書き(draft)は公開画面に出さない
        .where((article) => article.status == 'published')
        .toList();

    // API側のorderBy仕様が未確定のため、取得後にアプリ側で新しい順に並べ替える
    articles.sort((a, b) {
      if (a.publishedAt == null && b.publishedAt == null) return 0;
      if (a.publishedAt == null) return 1;
      if (b.publishedAt == null) return -1;
      return b.publishedAt!.compareTo(a.publishedAt!);
    });

    return articles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('りーろぐ'),
      ),
      body: FutureBuilder<List<EmdashArticle>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return SafeArea(
              child: Center(
                child: Text('記事の読み込みに失敗しました。\n${snapshot.error ?? ''}'),
              ),
            );
          }

          final articles = snapshot.data!;
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                final palette = AppColors.rss(context);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Material(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailPage(
                              title: article.title,
                              pubDate: article.publishedAt,
                              htmlContent: portableTextToHtml(article.body),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: palette.icon.withOpacity(0.15),
                              child: Icon(Icons.article_outlined,
                                  color: palette.icon, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: palette.text,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (article.publishedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${article.publishedAt!.year}/${article.publishedAt!.month}/${article.publishedAt!.day}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.text.withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
