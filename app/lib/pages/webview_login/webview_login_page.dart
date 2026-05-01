import 'package:flutter/material.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// WebView login page for source authentication
class WebViewLoginPage extends StatefulWidget {
  final String sourceKey;
  final String loginUrl;
  final void Function(String cookies)? onLoginComplete;

  const WebViewLoginPage({
    super.key,
    required this.sourceKey,
    required this.loginUrl,
    this.onLoginComplete,
  });

  @override
  State<WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<WebViewLoginPage> {
  bool _isLoading = true;
  String? _error;
  final List<String> _cookies = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          if (_cookies.isNotEmpty)
            TextButton(
              onPressed: _completeLogin,
              child: const Text('Done'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildWebView(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    // Note: This is a placeholder implementation.
    // In a full implementation, you would use flutter_inappwebview
    // or url_launcher to open the login page.

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'WebView Login',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Source: ${widget.sourceKey}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open Login Page'),
            onPressed: () {
              // In a full implementation:
              // Use url_launcher to open the login URL
              // Or use flutter_inappwebview for in-app login
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login URL: ${widget.loginUrl}'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'After logging in, copy the cookies and paste them below:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cookies',
                hintText: 'Paste cookies here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _cookies.clear();
                  _cookies.add(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_cookies.isNotEmpty)
            ElevatedButton(
              onPressed: _completeLogin,
              child: const Text('Complete Login'),
            ),
        ],
      ),
    );
  }

  void _completeLogin() {
    if (_cookies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter cookies first')),
      );
      return;
    }

    // Save cookies to source
    final source = NekoComicSourceManager().find(widget.sourceKey);
    if (source != null) {
      source.setCookies(_cookies.join('; '));
    }

    widget.onLoginComplete?.call(_cookies.join('; '));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login completed!')),
    );

    Navigator.of(context).pop(true);
  }
}
