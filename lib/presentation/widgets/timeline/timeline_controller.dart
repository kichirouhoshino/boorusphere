import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

final timelineControllerProvider =
    ChangeNotifierProvider.autoDispose<TimelineController>(
        (ref) => throw UnimplementedError());

class TimelineController extends ChangeNotifier {
  TimelineController({
    required this.scrollController,
    this.onLoadMore,
  }) {
    scrollController.addListener(_autoLoadMore);
  }

  final AutoScrollController scrollController;
  final Future<void> Function()? onLoadMore;

  // Guard against re-entrant / concurrent load-more calls that would stack up
  // on every scroll tick and cause excessive rebuilds.
  bool _loading = false;

  Future<void> _autoLoadMore() async {
    if (_loading) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.extentAfter < 200) {
      _loading = true;
      try {
        await onLoadMore?.call();
      } finally {
        _loading = false;
      }
    }
  }

  void scrollTo(int index) {
    if (!scrollController.hasClients) return;

    scrollController.scrollToIndex(index);
  }

  @override
  void dispose() {
    scrollController.removeListener(_autoLoadMore);
    super.dispose();
  }
}
