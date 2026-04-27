import 'package:flutter/material.dart';

/// Mixin for managing loading state in StatefulWidget
mixin NekoLoadingStateMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  bool get isLoading;
  Object? get error;
  Widget buildContent(BuildContext context);
  Future<void> loadData();

  void retry() {
    setState(() {});
    loadData();
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoading();
    }

    if (error != null) {
      return buildError(context, error!);
    }

    return buildContent(context);
  }
}

/// Abstract class for loading state management
abstract class NekoLoadingState<T extends StatefulWidget, S> extends State<T> {
  bool isLoading = true;
  S? data;
  Object? error;

  Future<S> loadData();

  void retry() {
    setState(() {
      isLoading = true;
      error = null;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await loadData();
      if (mounted) {
        setState(() {
          data = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context, S data);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoading();
    }

    if (error != null) {
      return buildError(context, error!);
    }

    return buildContent(context, data!);
  }
}

/// Sliver-based loading state
abstract class NekoSliverLoadingState<T extends StatefulWidget, S>
    extends NekoLoadingState<T, S> {
  @override
  Widget buildLoading() {
    return SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    return SliverFillRemaining(
      child: buildError(context, error),
    );
  }
}
