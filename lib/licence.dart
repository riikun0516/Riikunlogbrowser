import 'package:flutter/material.dart';
class license extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ライセンス'),
      ),
      body: ElevatedButton(
        child: Text('ライセンスページの表示'),
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'りーろぐブラウザ',
          applicationVersion: '2026.09.10-rev0',
        ),
      ),
    );
  }
}