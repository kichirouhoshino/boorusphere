import 'dart:async';

import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/presentation/provider/booru/post_headers_factory.dart';
import 'package:boorusphere/presentation/utils/extensions/post.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

class VideoPostSource {
  VideoPostSource({
    this.progress = const DownloadProgress('', 0, 0),
    this.controller,
    this.error,
  });

  final DownloadProgress progress;
  final VideoPlayerController? controller;

  /// Non-null when the video player failed to initialize (e.g. unsupported
  /// codec). The UI should show a fallback/error state in this case.
  final String? error;

  bool get hasError => error != null;

  VideoPostSource copyWith({
    DownloadProgress? progress,
    VideoPlayerController? controller,
    String? error,
  }) {
    return VideoPostSource(
      progress: progress ?? this.progress,
      controller: controller ?? this.controller,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(covariant VideoPostSource other) {
    if (identical(this, other)) return true;

    return other.progress == progress &&
        other.controller == controller &&
        other.error == error;
  }

  @override
  int get hashCode => progress.hashCode ^ controller.hashCode ^ error.hashCode;
}

VideoPostSource useVideoPostSource(
  WidgetRef ref, {
  required Post post,
  required bool active,
}) {
  return use(_VideoPostHook(ref, post: post, active: active));
}

class _VideoPostHook extends Hook<VideoPostSource> {
  const _VideoPostHook(
    this.ref, {
    required this.post,
    required this.active,
  });

  final WidgetRef ref;
  final Post post;
  final bool active;

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends HookState<VideoPostSource, _VideoPostHook> {
  _VideoPostState();

  VideoPostSource source = VideoPostSource();

  void onFileStream(FileResponse event) {
    if (!context.mounted) return;

    if (event is DownloadProgress) {
      setState(() {
        source = source.copyWith(progress: event);
      });
    } else if (event is FileInfo) {
      final controller = VideoPlayerController.file(event.file,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
        ..setLooping(true);
      final size = event.file.statSync().size;
      final prog = DownloadProgress(event.originalUrl, size, size);

      setState(() {
        source = source.copyWith(controller: controller, progress: prog);
      });
    }
  }

  Future<void> createController() async {
    if (!hook.active) return;

    final headers =
        hook.ref.read(postHeadersFactoryProvider(hook.post, cookies: []));

    final uri = Uri.parse(hook.post.content.url);

    try {
      final controller = VideoPlayerController.networkUrl(uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          httpHeaders: headers);
      unawaited(controller.setLooping(true));
      final prog = DownloadProgress(hook.post.content.url, 1, 1);

      setState(() {
        source = source.copyWith(controller: controller, progress: prog);
      });
    } catch (e) {
      // Codec or platform not supported — surface the error to the UI so it
      // can show a graceful fallback rather than a blank/stuck screen.
      setState(() {
        source = VideoPostSource(error: e.toString());
      });
    }
  }

  void destroyController() {
    source.controller?.pause();
    source.controller?.dispose();
    source = VideoPostSource();
  }

  @override
  void initHook() {
    super.initHook();
    createController();
  }

  @override
  void didUpdateHook(_VideoPostHook oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.active != hook.active) {
      destroyController();
      createController();
    }
  }

  @override
  VideoPostSource build(BuildContext context) => source;

  @override
  void dispose() {
    destroyController();
    super.dispose();
  }

  @override
  String get debugLabel => 'useVideoPost';
}
