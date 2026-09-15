import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プライバシーポリシー',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'このアプリは、ユーザーの個人情報を収集しません。'
                  'すべてのデータはアプリ内、または一時的なキャッシュとしてのみ扱われます。',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),

            Text(
              'アクセス解析について',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'このアプリは、サービス向上のためにGoogle Analyticsを使用する可能性がありますが、'
                  '個人を特定する情報は収集しません。',
              style: TextStyle(fontSize: 16),
            ),
            // ... 必要に応じて他の項目を追加 ...
            SizedBox(height: 24),

            Text(
              '制定日: 2025年8月16日',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}