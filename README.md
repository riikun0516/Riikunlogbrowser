# りーろぐブラウザ (riikunlogbrowser)

個人ブログ「りーろぐ」とポッドキャスト番組「RadioStrike」を、1つのアプリでまとめて楽しめるコンパニオンアプリです。

## 対応プラットフォーム

- iOS
- macOS
- Android
- Windows
- Linux (Flathub / Snap Store)

## 主な機能

- **りーろぐ**: Emdash CMS 経由でブログ記事の一覧・詳細を閲覧
- **RadioStrike**: WordPress の Podcast RSS フィードを取得し、エピソード一覧・再生(media_kit)
- **Webブラウザ**: アプリ内蔵ブラウザ(iOS/macOS/Android: `webview_flutter`、Windows: `webview_flutter_windows`、Linux: システムの既定ブラウザを起動)
- **お知らせ**: microCMS 経由で運営からのお知らせを表示

ログイン・アカウント登録・課金機能は一切ありません。

## セットアップ

詳しい手順は [ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md) を参照してください。最短では以下の通りです。

```bash
flutter pub get
```

各プラットフォームのビルド・実行は通常の Flutter コマンドと同じです。

```bash
flutter run -d macos
flutter run -d windows
flutter run -d linux
flutter build ios
flutter build appbundle
```

## 開発上の注意点(プラットフォーム別の既知の癖)

複数環境(Windows/Mac/Linux)で並行開発してきた経緯があり、同じ問題を繰り返さないための注意点をまとめています。

### iOS
- **UIScene ライフサイクル移行済み**(iOS 26 以降で必須)。自動移行機能で対応済み:
  ```bash
  flutter config --enable-uiscene-migration
  ```
  `AppDelegate.swift` は `FlutterImplicitEngineDelegate` に準拠し、`Info.plist` に `UIApplicationSceneManifest` を含む。**手動でこの構造を崩さないこと**(黒画面の原因になる)。
- `NSMicrophoneUsageDescription` が `Info.plist` に必要(media_kit が内部でマイク関連APIを参照するため、実際には未使用でも申告が必須)。

### macOS
- Xcode の Archive 前に必ず `flutter clean && flutter pub get` を実行し、`Generated.xcconfig` が最新であることを確認する。
- `LSApplicationCategoryType` が `Info.plist` に必要(App Store 申請で必須)。

### Windows
- `webview_windows` ではなく `webview_flutter_windows` を使用(MSVC C++23 関連の互換性のため)。
- Swift Package Manager は無効化している(`pubspec.yaml` の `flutter.config.enable-swift-package-manager: false`)。これは media_kit 系プラグインが SPM 未対応のため。

### Linux
- **内蔵ブラウザではなく、システムの既定ブラウザを起動する方式**(`webview_page.dart` の `openUrl()` 参照)。`webview_all_linux` はフォーカスを外すと描画が消える既知の不具合があり不採用。
- `media_kit` の libmpv 自動検出が Snap 環境で失敗するため、`main.dart` で Linux のみ明示的にパスを指定している。
- Snap パッケージ化の際は、`gnome` 拡張機能と重複する GTK/GLib 系ライブラリを `prime` から除外する必要がある(`snap/snapcraft.yaml` 参照)。また `libmpv.so.2` → `.so.1` の互換シンボリックリンク、`libblas`/`liblapack` の `update-alternatives` シンボリックリンクを手動生成している。

### 全プラットフォーム共通
- RadioStrike の RSS フィード取得には、WordPress 側の Bot 対策(WAF)を回避するため、ブラウザ相当の `User-Agent` ヘッダーを付与している(`podcast_list_page.dart`)。

## リポジトリ運用ルール

複数マシン(Mac / Windows / Linux)で作業するため、**このリポジトリを唯一の正解**として扱う。

- 作業前に必ず `git pull`
- 作業後は必ず `git push`
- 複数マシンで同時に同じファイルを編集しない

## CI/CD

- `.github/workflows/snap.yml`: タグ push (`v*`) をトリガーに Snap をビルド・実機起動確認・Snap Store への公開まで自動実行。
