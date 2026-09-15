// EmdashのPortable Text形式(構造化JSONの本文)を、
// 既存のArticleDetailPage(flutter_html)にそのまま渡せるHTML文字列に変換する。
//
// 対応している要素:
// - 段落(normal) / 見出し(h1〜h4) / 引用(blockquote)
// - 箇条書き(bullet) / 番号付きリスト(number)
// - 太字(strong) / 斜体(em) / リンク(markDefsのlinkタイプ)
//
// 画像ブロックなど、textブロック以外の要素は現時点ではスキップしている。
// 実際のAPIレスポンスを見て、必要であれば拡張してほしい。
String portableTextToHtml(dynamic body) {
  if (body == null) return '';
  // フィールドが単純な文字列(プレーンテキストやすでにHTML)の場合はそのまま返す
  if (body is String) return body;
  if (body is! List) return '';

  final buffer = StringBuffer();
  String? openListType; // 'bullet' | 'number' | null

  void closeListIfNeeded() {
    if (openListType == 'bullet') {
      buffer.write('</ul>');
    } else if (openListType == 'number') {
      buffer.write('</ol>');
    }
    openListType = null;
  }

  String escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  for (final block in body) {
    if (block is! Map) continue;
    final blockType = block['_type'];

    // "block"(テキストブロック)以外は現状未対応のためスキップ
    if (blockType != 'block') {
      closeListIfNeeded();
      continue;
    }

    final listItem = block['listItem'] as String?;

    if (listItem != null) {
      if (openListType != listItem) {
        closeListIfNeeded();
        buffer.write(listItem == 'number' ? '<ol>' : '<ul>');
        openListType = listItem;
      }
    } else {
      closeListIfNeeded();
    }

    final markDefs = (block['markDefs'] as List?)?.cast<Map>() ?? const [];
    final children = (block['children'] as List?)?.cast<Map>() ?? const [];

    final innerHtml = children.map((span) {
      var text = escape(span['text'] as String? ?? '');
      // テキスト内に生の改行が埋め込まれているケースに対応(<br>に変換)
      text = text.replaceAll('\r\n', '\n').replaceAll('\n', '<br>');
      final marks = (span['marks'] as List?)?.cast<String>() ?? const [];

      for (final mark in marks) {
        if (mark == 'strong') {
          text = '<strong>$text</strong>';
        } else if (mark == 'em') {
          text = '<em>$text</em>';
        } else {
          // strong/em以外はmarkDefsのキー(リンクなど)として解決する
          final def = markDefs.firstWhere(
            (d) => d['_key'] == mark,
            orElse: () => const {},
          );
          if (def['_type'] == 'link' && def['href'] != null) {
            text = '<a href="${def['href']}">$text</a>';
          }
        }
      }
      return text;
    }).join();

    if (listItem != null) {
      buffer.write('<li>$innerHtml</li>');
      continue;
    }

    final style = block['style'] as String? ?? 'normal';
    switch (style) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        buffer.write(
            '<$style style="margin:1em 0 0.5em 0;">$innerHtml</$style><br>');
        break;
      case 'blockquote':
        buffer.write(
            '<blockquote style="margin:0 0 1em 0;">$innerHtml</blockquote><br>');
        break;
      default:
        // margin指定がflutter_htmlに無視される場合の保険として、
        // <p>の余白だけでなく明示的な<br>でも段落を区切る
        buffer.write('<p style="margin:0 0 1em 0;">$innerHtml</p><br>');
    }
  }

  closeListIfNeeded();
  return buffer.toString();
}
