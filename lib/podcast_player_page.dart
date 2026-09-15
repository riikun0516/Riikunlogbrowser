import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // just_audio の代わりに media_kit をインポート
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'dart:async'; // Stream のために必要
import 'app_colors.dart';

class PodcastPlayerPage extends StatefulWidget {
  final String title;
  final String audioUrl;
  final String? imageUrl;
  final String? description;

  const PodcastPlayerPage({
    super.key,
    required this.title,
    required this.audioUrl,
    this.imageUrl,
    this.description,
  });

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  // ▼▼▼ just_audio から media_kit の Player に変更 ▼▼▼
  final Player _player = Player();

  // 状態管理用のStream（media_kit の stream を利用）
  Stream<Duration> get _positionDataStream => _player.stream.position;
  Stream<Duration> get _durationStream => _player.stream.duration;
  Stream<Duration> get _bufferedPositionStream => _player.stream.buffer;
  Stream<bool> get _playerStateStream => _player.stream.playing;
  // ▲▲▲ ここまで変更 ▲▲▲


  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // media_kit の Player で再生を開始
      await _player.open(Media(widget.audioUrl), play: true);
      
    } catch (e) {
      // エラーが発生したらダイアログで表示
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('再生エラー'),
            content: Text('音声の読み込みに失敗しました。\n\n詳細: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose(); // Player を破棄
    super.dispose();
  }

  void _showDescriptionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('概要'),
        content: SingleChildScrollView( // 長い説明に対応
          child: Text(widget.description ?? '概要はありません。'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ? Image.network(
                widget.imageUrl!, 
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildArtworkPlaceholder();
                },
              )
            : _buildArtworkPlaceholder(),
      ),
    );
  }
  
  Widget _buildArtworkPlaceholder() {
    final palette = AppColors.podcast(context);
    return Container(
      color: palette.background,
      child: Center(
        child: Icon(Icons.music_note, color: palette.icon, size: 50),
      ),
    );
  }


  Widget _buildProgressBar() {
    // media_kit の Stream を使って ProgressBar を構築
    return StreamBuilder<Duration>(
      stream: _durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: _positionDataStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: _bufferedPositionStream,
              builder: (context, bufferedSnapshot) {
                final total = durationSnapshot.data ?? Duration.zero;
                final progress = positionSnapshot.data ?? Duration.zero;
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final palette = AppColors.podcast(context);

                return ProgressBar(
                  progress: progress,
                  buffered: buffered,
                  total: total,
                  progressBarColor: palette.icon,
                  baseBarColor: palette.icon.withOpacity(0.15),
                  bufferedBarColor: palette.icon.withOpacity(0.3),
                  thumbColor: palette.icon,
                  timeLabelTextStyle: TextStyle(color: palette.text),
                  onSeek: (duration) {
                    _player.seek(duration);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlayPauseButton() {
    // media_kit の Stream を使ってボタンを構築
    return StreamBuilder<bool>(
      stream: _playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        final palette = AppColors.podcast(context);

        // ▼▼▼ just_audio の ProcessingState 判定を簡略化 ▼▼▼
        if (playing) {
          return IconButton(
            icon: const Icon(Icons.pause_rounded),
            iconSize: 64.0,
            color: palette.icon,
            onPressed: _player.pause,
          );
        } else {
           // 読み込み中や一時停止中、完了時など
          return IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            iconSize: 64.0,
            color: palette.icon,
            onPressed: _player.play,
            // TODO: 完了時はリプレイ処理（seek(0)）を追加すると尚良い
          );
        }
        // ▲▲▲ ここまで変更 ▲▲▲
      },
    );
  }

  Widget _buildPortraitLayout() {
    // SingleChildScrollViewで囲み、小さな画面でもはみ出さないようにする
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildArtwork(),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildProgressBar(),
          const SizedBox(height: 24),
          _buildPlayPauseButton(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 1, child: _buildArtwork()),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          // SingleChildScrollViewで囲む
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildProgressBar(),
                const SizedBox(height: 24),
                _buildPlayPauseButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.description != null && widget.description!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showDescriptionDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: OrientationBuilder(
            builder: (context, orientation) {
              return orientation == Orientation.portrait
                  ? _buildPortraitLayout()
                  : _buildLandscapeLayout();
            },
          ),
        ),
      ),
    );
  }
}