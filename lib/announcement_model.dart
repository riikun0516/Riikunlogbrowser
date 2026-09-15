import 'dart:convert';
import 'dart:typed_data';

// microCMSのレスポンス(生のバイト列)をパースして、Announcementオブジェクトのリストに変換する
List<Announcement> parseAnnouncements(Uint8List responseBodyBytes) {
  // response.body(文字列化済み)を経由すると文字コードが化けることがあるため、
  // 生のバイト列を直接UTF-8としてデコードする
  final decoded = jsonDecode(utf8.decode(responseBodyBytes));
  // microCMSのリスト形式APIは { "contents": [...], "totalCount": ..., ... } で返ってくる
  final contents = (decoded['contents'] as List).cast<Map<String, dynamic>>();
  return contents.map<Announcement>((json) => Announcement.fromJson(json)).toList();
}

// お知らせ一件分のデータ構造
class Announcement {
  final String id; // microCMSのIDは文字列
  final String title;
  final String content;
  final DateTime timestamp;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  // microCMSのJSONからAnnouncementオブジェクトに変換するファクトリ
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      // リッチエディタ項目の場合はHTML文字列が入る
      content: json['content'] as String,
      // publishedAt(公開日時)を優先し、無ければcreatedAt(作成日時)を使う
      timestamp: DateTime.parse(
        (json['publishedAt'] ?? json['createdAt']) as String,
      ),
    );
  }
}