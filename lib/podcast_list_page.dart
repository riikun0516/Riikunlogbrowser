import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'podcast_player_page.dart';
import 'app_colors.dart';

class PodcastListPage extends StatefulWidget {
  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> {
  Future<RssFeed>? _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = fetchRssFeed();
  }

  Future<RssFeed> fetchRssFeed() async {
    final response = await http.get(Uri.parse('https://wp.radiostrike.jp/feed/podcast/radiostrike'));
    if (response.statusCode == 200) {
      return RssFeed.parse(response.body);
    } else {
      throw Exception('Failed to load RSS feed');
    }
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
            // ▼▼▼ ここから修正 ▼▼▼
            return SafeArea(child: Center(child: Text('エラー: ${snapshot.error}')));
            // ▲▲▲ ここまで修正 ▲▲▲
          } else if (!snapshot.hasData || snapshot.data!.items == null) {
            // ▼▼▼ ここから修正 ▼▼▼
            return const SafeArea(child: Center(child: Text('記事がありません')));
            // ▲▲▲ ここまで修正 ▲▲▲
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
                              description: item.itunes?.summary,
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