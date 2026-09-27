import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:xml/xml.dart' as xml;
import 'podcast_player_page.dart';
import 'app_colors.dart';

class PodcastListPage extends StatefulWidget {
  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> {
  Future<RssFeed>? _feedFuture;
  // webfeed_plusはWordPressが全文を格納する<content:encoded>タグに対応していないため、
  // 生のXMLを直接読み取って、記事(link/guid)ごとの全文をここに保持する。
  final Map<String, String> _fullContentByKey = {};

  @override
  void initState() {
    super.initState();
    _feedFuture = fetchRssFeed();
  }

  Future<RssFeed> fetchRssFeed() async {
    final response = await http.get(
      Uri.parse('https://wp.radiostrike.jp/feed/podcast/radiostrike'),
      headers: {
        // WordPress側のBot対策(WAF等)が、ブラウザらしくないUser-Agentを
        // ブロックすることがあるため、通常のブラウザに近いUser-Agentを送る
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
                '(KHTML, like Gecko) Version/17.0 Safari/605.1.15',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      },
    );
    if (response.statusCode == 200) {
      _extractFullContent(response.body);
      return RssFeed.parse(response.body);
    } else {
      throw Exception(
          'Failed to load RSS feed (status: ${response.statusCode})');
    }
  }

  // <content:encoded>(WordPressの全文フィールド)を、<link>または<guid>をキーにして抜き出す
  void _extractFullContent(String rawXml) {
    try {
      final doc = xml.XmlDocument.parse(rawXml);
      for (final item in doc.findAllElements('item')) {
        final linkElements = item.findElements('link');
        final guidElements = item.findElements('guid');
        final link =
            linkElements.isNotEmpty ? linkElements.first.innerText.trim() : null;
        final guid =
            guidElements.isNotEmpty ? guidElements.first.innerText.trim() : null;
        final key = link ?? guid;
        if (key == null || key.isEmpty) continue;

        final encodedElements = item.findElements(
          'encoded',
          namespace: 'http://purl.org/rss/1.0/modules/content/',
        );
        final encoded =
            encodedElements.isNotEmpty ? encodedElements.first.innerText : null;
        if (encoded != null && encoded.trim().isNotEmpty) {
          _fullContentByKey[key] = encoded;
        }
      }
    } catch (_) {
      // 全文の抽出に失敗しても、一覧表示自体は継続させる
      // (この場合はdescription/itunes:summaryへフォールバックされる)
    }
  }

  // 優先順位: content:encoded(全文) > description > itunes:summary(短い要約)
  String? _descriptionFor(RssItem item) {
    final key = item.link ?? item.guid;
    final fullContent = key != null ? _fullContentByKey[key] : null;
    if (fullContent != null && fullContent.trim().isNotEmpty) {
      return fullContent;
    }
    if (item.description != null && item.description!.trim().isNotEmpty) {
      return item.description;
    }
    return item.itunes?.summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RadioStrike')),
      body: FutureBuilder<RssFeed>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return SafeArea(child: Center(child: Text('エラー: ${snapshot.error}')));
          } else if (!snapshot.hasData || snapshot.data!.items == null) {
            return const SafeArea(child: Center(child: Text('記事がありません')));
          }

          final feed = snapshot.data!;
          final items = feed.items!;
          // エピソード個別に画像がない場合、番組全体(チャンネル)の画像にフォールバックする
          final channelImageUrl = feed.itunes?.image?.href ?? feed.image?.url;
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemImageUrl =
                    item.itunes?.image?.href ?? channelImageUrl;
                final palette = AppColors.podcast(context);
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
                            builder: (context) => PodcastPlayerPage(
                              title: item.title ?? 'タイトルなし',
                              audioUrl: item.enclosure?.url ?? '',
                              imageUrl: itemImageUrl,
                              description: _descriptionFor(item),
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
                              child: Icon(Icons.play_arrow_rounded,
                                  color: palette.icon),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title ?? 'タイトルなし',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: palette.text,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.pubDate != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.pubDate.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.text.withOpacity(0.65),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
