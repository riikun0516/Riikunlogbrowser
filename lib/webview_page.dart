import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

// Linuxではwebview_all_linuxがまだ不安定(フォーカスを外すと描画が消える)なため、
// LinuxだけシステムのデフォルトブラウザでURLを開く。他プラットフォームは
// これまで通りアプリ内蔵のWebViewPageに遷移する。
Future<void> openUrl(BuildContext context, String url) async {
  if (Platform.isLinux) {
    final uri = _normalizeUrl(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクを開けませんでした')),
        );
      }
    }
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(initialUrl: url),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String? initialUrl;
  const WebViewPage({super.key, this.initialUrl});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

// リンクのhrefがスキーム無し(相対URLや"example.com"のような不完全な形)の場合、
// そのままではWebViewが空白のまま止まってしまうため、ここで補完する。
Uri _normalizeUrl(String url) {
  final uri = Uri.parse(url);
  if (uri.hasScheme) {
    return uri;
  }
  if (url.startsWith('//')) {
    // "//example.com/path" のようなプロトコル相対URL
    return Uri.parse('https:$url');
  }
  if (url.startsWith('/')) {
    // サイト内の絶対パスのみのリンクは、正しいドメインが分からないため
    // ひとまず検索に回す(誤動作より安全)
    return Uri.parse('https://www.google.com/search?q=$url');
  }
  // "example.com/path" のようなスキーム省略のURL
  return Uri.parse('https://$url');
}

class _WebViewPageState extends State<WebViewPage> {
  final _windowsController = WebviewController();
  // Linuxではwebview_all_linuxが webview_flutter の連合プラグイン実装として
  // 自動的に登録されるため、WebViewController はそのまま使い回せる。
  late final WebViewController _mobileController;
  final _textController = TextEditingController();

  bool _isWindows = false;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _isWindows = Platform.isWindows;
    _initWebView();
  }

  @override
  void dispose() {
    if (_isWindows) {
      _windowsController.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    final normalizedInitialUrl =
        widget.initialUrl != null ? _normalizeUrl(widget.initialUrl!) : null;

    if (_isWindows) {
      await _windowsController.initialize();
      _windowsController.url.listen((url) {
        _textController.text = url;
      });
      if (normalizedInitialUrl != null) {
        await _windowsController.loadUrl(normalizedInitialUrl.toString());
      }
    } else {
      // iOS/Android/macOS/Linux共通(それぞれの連合プラグイン実装に自動的に振り分けられる)
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _textController.text = url;
            },
          ),
        );
      if (normalizedInitialUrl != null) {
        await _mobileController.loadRequest(normalizedInitialUrl);
      }
    }

    if (mounted) {
      setState(() {
        _isWebViewReady = true;
        if (normalizedInitialUrl != null) {
          _textController.text = normalizedInitialUrl.toString();
        }
      });
    }
  }

  void _loadUrl(String url) {
    final uri = _normalizeUrl(url);

    if (_isWindows) {
      _windowsController.loadUrl(uri.toString());
    } else {
      _mobileController.loadRequest(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.web(context);
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.public, size: 18, color: palette.icon),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: palette.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '検索またはURLを入力',
                    hintStyle: TextStyle(color: palette.text.withOpacity(0.6)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (value) => _loadUrl(value),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isWindows) {
                await _windowsController.goBack();
              } else {
                if (await _mobileController.canGoBack()) {
                  await _mobileController.goBack();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (_isWindows) {
                await _windowsController.goForward();
              } else {
                if (await _mobileController.canGoForward()) {
                  await _mobileController.goForward();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isWebViewReady
            ? (_isWindows
                ? Webview(_windowsController)
                : WebViewWidget(controller: _mobileController))
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
