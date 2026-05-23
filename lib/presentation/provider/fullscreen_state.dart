import 'package:boorusphere/domain/provider.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fullscreen_state.g.dart';

@riverpod
class FullscreenState extends _$FullscreenState {
  List<DeviceOrientation> _lastOrientations = [];

  @override
  bool build() {
    ref.onDispose(reset);
    _lastOrientations = [];
    return false;
  }

  Future<void> toggle({bool shouldLandscape = false}) async {
    state = !state;
    final orientations = state && shouldLandscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : <DeviceOrientation>[];

    if (orientations != _lastOrientations) {
      _lastOrientations = orientations;
      await SystemChrome.setPreferredOrientations(orientations);
    }

    if (state) {
      // Delay native immersive overlay changes slightly to allow the
      // 300ms UI slide/fade out animations to finish smoothly first.
      Future.delayed(const Duration(milliseconds: 250), () async {
        if (state) {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        }
      });
    } else {
      await unfullscreen();
    }
  }

  Future<void> unfullscreen() async {
    final envRepo = ref.read(envRepoProvider);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);
    if (envRepo.sdkVersion >= 29) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void reset() {
    SystemChrome.setPreferredOrientations([]);
    unfullscreen();
  }
}
