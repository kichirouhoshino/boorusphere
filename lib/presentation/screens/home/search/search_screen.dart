import 'package:boorusphere/presentation/screens/home/search/search_bar.dart';
import 'package:boorusphere/presentation/screens/home/search/search_bar_controller.dart';
import 'package:boorusphere/presentation/screens/home/search/search_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen =
        ref.watch(searchBarControllerProvider.select((it) => it.isOpen));
    final animator =
        useAnimationController(duration: const Duration(milliseconds: 300));
    
    final animation = useMemoized(
      () => CurvedAnimation(parent: animator, curve: Curves.easeInOutCubic),
      [animator],
    );

    final opacityAnimation = useMemoized(
      () => Tween<double>(begin: 0.5, end: 1.0).animate(animation),
      [animation],
    );

    final slideAnimation = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      [animation],
    );

    useListenable(animator);

    useEffect(() {
      isOpen ? animator.forward() : animator.reverse();
    }, [isOpen]);

    final isVisible = isOpen || !animator.isDismissed;

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (isVisible)
            FadeTransition(
              opacity: opacityAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: RepaintBoundary(
                  child: SearchSuggestion(isAnimating: animator.isAnimating),
                ),
              ),
            ),
          HomeSearchBar(scrollController: scrollController),
        ],
      ),
    );
  }
}
