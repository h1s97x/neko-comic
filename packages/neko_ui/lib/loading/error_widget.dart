import 'package:flutter/material.dart';

/// Error widget for displaying error states
class NekoErrorWidget extends StatelessWidget {
  const NekoErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.action,
    this.withAppbar = false,
    this.icon,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final Widget? action;
  final bool withAppbar;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action != null) ...[
                  action!,
                  const SizedBox(width: 12),
                ],
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (withAppbar) {
      content = Column(
        children: [
          AppBar(
            title: const Text(''),
            automaticallyImplyLeading: false,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Material(child: content);
  }
}

/// Empty state widget
class NekoEmptyWidget extends StatelessWidget {
  const NekoEmptyWidget({
    super.key,
    this.title = 'No data',
    this.message,
    this.icon,
    this.action,
    this.withAppbar = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  final bool withAppbar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );

    if (withAppbar) {
      content = Column(
        children: [
          AppBar(
            title: const Text(''),
            automaticallyImplyLeading: false,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Material(child: content);
  }
}

/// Network error specific widget
class NekoNetworkError extends StatelessWidget {
  const NekoNetworkError({
    super.key,
    required this.message,
    this.onRetry,
    this.withAppbar = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool withAppbar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCloudflare = _isCloudflareError(message);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCloudflare ? Icons.security : Icons.wifi_off,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isCloudflare ? 'Verification Required' : 'Network Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCloudflare
                  ? 'Cloudflare verification is required. Please complete the verification and try again.'
                  : message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(isCloudflare ? 'Verify' : 'Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (withAppbar) {
      content = Column(
        children: [
          AppBar(
            title: const Text(''),
            automaticallyImplyLeading: false,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Material(child: content);
  }

  bool _isCloudflareError(String message) {
    return message.contains('cloudflare') ||
        message.contains('Cloudflare') ||
        message.contains('cf-') ||
        message.contains('challenge');
  }
}
