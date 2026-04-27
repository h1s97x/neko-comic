import 'package:flutter/material.dart';

/// Loading indicator widget for list views
class NekoListLoadingIndicator extends StatelessWidget {
  const NekoListLoadingIndicator({
    super.key,
    this.height = 80,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: const Center(
        child: FiveDotLoadingAnimation(),
      ),
    );
  }
}

/// Sliver loading indicator for sliver-based scrolling
class NekoSliverLoadingIndicator extends StatelessWidget {
  const NekoSliverLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Use SliverList to ensure lazy loading animation
    return SliverList.list(
      children: const [
        SizedBox.shrink(),
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

/// Five dot loading animation
class FiveDotLoadingAnimation extends StatefulWidget {
  const FiveDotLoadingAnimation({super.key});

  @override
  State<FiveDotLoadingAnimation> createState() => _FiveDotLoadingAnimationState();
}

class _FiveDotLoadingAnimationState extends State<FiveDotLoadingAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.3 + _animations[index].value * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Skeleton loading shimmer effect
class NekoShimmerLoading extends StatelessWidget {
  const NekoShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton card for loading states
class NekoSkeletonCard extends StatelessWidget {
  const NekoSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 3,
            child: NekoShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NekoShimmerLoading(width: 100, height: 14),
                  const SizedBox(height: 8),
                  const NekoShimmerLoading(width: 60, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton grid for loading states
class NekoSkeletonGrid extends StatelessWidget {
  const NekoSkeletonGrid({
    super.key,
    this.crossAxisCount = 3,
    this.itemCount = 9,
  });

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NekoSkeletonCard(),
    );
  }
}
