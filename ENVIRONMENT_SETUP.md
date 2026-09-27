# 環境構築マニュアル

このプロジェクトの開発環境を新しいマシンに構築する際の手順です。過去に実際につまずいた箇所を踏まえてまとめています。

---

## 共通: リポジトリの取得

```bash
git clone https://github.com/riikun0516/riikunlogbrowser.git
cd riikunlogbrowser
flutter pub get
```

**GitHub認証について**: パスワード認証は使えません。以下のどちらかを設定してください。

- **GitHub CLI(推奨、ブラウザでワンクリック認証)**
  ```bash
  brew install gh   # Windowsは winget install GitHub.cli
  gh auth login
  ```
- **個人アクセストークン**: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) で発行(`repo`・`workflow`スコープにチェック)。`git push`時のパスワード欄に貼り付ける。

SourceTreeを使う場合は、`ツール` → `オプション` → `認証`タブから`OAuth`でアカウントを追加し、「デフォルトに設定」しておくこと。

---

## Windows

### 1. 一括インストール(Chocolatey)

```powershell
# Chocolatey未導入の場合は先に公式サイトの手順でインストール
choco install flutter git androidstudio vscode -y
flutter upgrade
```

### 2. Android SDKライセンス

```powershell
flutter doctor --android-licenses
```

うまく通らない場合、ライセンスファイルを手動で `C:\Users\<ユーザー名>\AppData\Local\Android\Sdk\licenses\` に配置する必要がある場合がある。

### 3. MSIX(ストア配布)用証明書

`key.pfx` が必要(`pubspec.yaml` の `msix_config` 参照)。パスワードが平文でファイルに入っているため、リポジトリ外で厳重に管理すること。

`msix_config.logo_path` は `pubspec.yaml` からの相対パス(`"logo.png"`)で指定すること。以前 `D:/riikunlogbrowser/logo.png` のような絶対パス・ドライブ固定になっていたことがあり、別のマシン・別のドライブにプロジェクトを置くとビルドが失敗する原因になっていた。

### 4. 動作確認(デバッグ用途のみ)

以下はあくまで**開発中の動作確認用**であり、実際の配布物ではない。

```powershell
flutter doctor -v
flutter run -d windows
```

`flutter build windows` も同様に、生成される実行ファイル一式(`build/windows/x64/runner/Release/`)はそのままでは配布しない(署名もストア用パッケージ化もされていない)。

### 5. 実際のリリースビルド(MSIX配布)

配布物は **MSIX形式**でパッケージ化する。`pubspec.yaml` に `msix_config` を設定済みなら、以下の1コマンドで完結する(内部で `flutter build windows` 相当のビルドも実行される)。

```powershell
dart run msix:create
```

成功すると `build/windows/x64/runner/Release/<アプリ名>.msix` が生成される。これが配布・Microsoft Store申請用の実体。

**動作確認(インストールしてみる)**

```powershell
Add-AppxPackage -Path build\windows\x64\runner\Release\riikunlogbrowser.msix
```

**Microsoft Storeへの申請**は、Partner Centerにこの `.msix` ファイルをアップロードする形になる(Partner Center側の操作は別途)。

**バージョンを上げてビルドし直す場合**は、`pubspec.yaml` の `version:` と `msix_config.msix_version` の両方を更新してから `dart run msix:create` を実行すること(片方だけ上げ忘れるとストア申請時にリジェクトされる)。

---

## macOS

### 1. Xcode本体

App StoreからXcodeをインストール後、コマンドラインツールを有効化。

```bash
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -license accept
```

### 2. Flutter SDK・CocoaPods

```bash
brew install cocoapods
```

Flutter SDKは公式サイトからダウンロードするか、既にWindowsで使っているならリポジトリのみ共有しSDKは各マシンで別途用意する。

### 3. 署名設定

- Apple Developer Programに登録済みのアカウントでXcodeにサインイン(`Xcode` → `Settings` → `Accounts`)
- `ios/Runner.xcworkspace` / `macos/Runner.xcworkspace` を開き、`Signing & Capabilities` で Team を設定(Automatically manage signing を推奨)

### 4. ビルド前の毎回のお約束

Xcodeで直接Archiveする前に、**必ず一度ターミナルから通しておく**とトラブルが少ない。

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
cd macos && pod install --repo-update && cd ..
```

### 5. ストレージ容量に注意

Xcodeのビルドキャッシュ・アーカイブは非常に大きくなる。空き容量が少ないと、黒画面・ビルド停止・原因不明のエラーの温床になる。定期的に整理すること。

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
# Xcode の Window > Organizer から不要な古いアーカイブも削除する
```

---

## Linux(WSL2上での開発を含む)

### WSL2自体のセットアップ(Windows機で開発する場合)

```powershell
wsl --install -d Ubuntu
```

再起動後、Ubuntu初回セットアップを済ませる。

### 必須パッケージ

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
  libstdc++-12-dev git curl unzip libmpv-dev mpv squashfs-tools
```

### Flutter SDK

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter config --enable-linux-desktop
flutter doctor
```

**注意**: WindowsとWSLの両方にFlutterが入っていると `PATH` の重複でどちらが呼ばれるか混乱しやすい。`which flutter` で `/home/<user>/flutter/bin/flutter` を指しているか確認すること。

### プロジェクトの配置場所

**必ずWSL側のファイルシステム(`~/`配下)にプロジェクトを置くこと。** `/mnt/c/...` 上ではCMakeのビルドが失敗する(WindowsドライブとLinuxのファイル操作の非互換のため)。

```bash
cd ~
git clone https://github.com/riikun0516/riikunlogbrowser.git
cd riikunlogbrowser
flutter pub get
```

### WSL2でのGPU描画(WSLg)

デフォルトではソフトウェアレンダリングになり重い・不安定なことがある。NVIDIA GPU環境では以下でハードウェアアクセラレーションを有効化できる。

```bash
echo 'export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export GALLIUM_DRIVER=d3d12' >> ~/.bashrc
source ~/.bashrc
```

確認:
```bash
glxinfo | grep "OpenGL renderer"
# "D3D12 (...)" と表示されればOK
```

### Snapパッケージのビルド

**WSL2上での `snapcraft`/`LXD` を使ったビルドは推奨しない**(マウント名前空間まわりのカーネル制約で頻繁に失敗する)。ビルドはGitHub Actions(`.github/workflows/snap.yml`)に任せ、タグをpushして実行する運用にしている。

```bash
git tag v2026.MM.DD
git push origin v2026.MM.DD
```

ローカルで動作確認だけしたい場合は、通常の `flutter run -d linux` で問題ない(Snapのサンドボックス特有の問題は再現しないため、あくまで簡易確認用)。

---

## 全プラットフォーム共通のチェックリスト(新しいマシンで動かない時に見る場所)

1. `flutter doctor -v` で赤字(✗)がないか
2. `flutter clean && flutter pub get` を一度実行したか
3. ネイティブの依存関係(`ios/Pods`、`macos/Pods`、`android`のGradleキャッシュ)を作り直したか
4. ディスクの空き容量は十分か(目安: 20GB以上)
5. `git pull` で最新の状態を取り込んでいるか
