import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'announcement_model.dart';
import 'announcement_detail_page.dart';
import 'app_colors.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late Future<List<Announcement>> _announcementsFuture;
  
  // ▼▼▼ microCMSの管理画面から確認して書き換えてください ▼▼▼
  // 管理画面URL "https://XXXX.microcms.io" の XXXX 部分
  static const String _serviceDomain = 'riikunlogbrowser';
  // 作成したAPIのエンドポイント名(一覧ページのURLの末尾など)
  static const String _endpoint = 'announcements';
  // 「APIキー」ページで発行したキー。公開アプリに埋め込むので、
  // 書き込み権限は付けず「GETのみ許可」のキーを使うことを推奨
  static const String _apiKey = 'LtqGUf34MTaikrftWDCG7NxBMVbCIOfdsubB';

  Uri get apiUrl => Uri.parse(
        'https://$_serviceDomain.microcms.io/api/v1/$_endpoint?limit=100&orders=-publishedAt',
      );

  @override
  void initState() {
    super.initState();
    _announcementsFuture = fetchAnnouncements();
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final response = await http.get(
        apiUrl,
        headers: {'X-MICROCMS-API-KEY': _apiKey},
      );

      if (response.statusCode == 200) {
        return parseAnnouncements(response.bodyBytes);
      } else {
        throw Exception('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('お知らせの読み込みに失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SafeArea(
              child: Center(child: Text('エラー: ${snapshot.error}')),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SafeArea(
              child: Center(child: Text('お知らせはありません。')),
            );
          }

          final announcements = snapshot.data!;
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                final palette = AppColors.announce(context);
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
                            builder: (_) => AnnouncementDetailPage(
                              announcement: announcement,
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
                              child: Icon(Icons.campaign_outlined,
                                  color: palette.icon, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: palette.text,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('yyyy/MM/dd')
                                        .format(announcement.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.text.withOpacity(0.65),
                                    ),
                                  ),
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