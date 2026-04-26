/// Cookie jar for managing cookies
class CookieJar {
  static final CookieJar _instance = CookieJar._();
  static CookieJar get instance => _instance;

  CookieJar._();

  final Map<String, Map<String, String>> _cookies = {};

  /// Set cookies for a domain
  void setCookies(String domain, List<CookieItem> cookies) {
    _cookies[domain] = {for (var c in cookies) c.name: c.value};
  }

  /// Get cookies for a domain
  Map<String, String> getCookies(String domain) {
    return _cookies[domain] ?? {};
  }

  /// Convert cookies to header string
  String cookiesToHeader(String domain) {
    final cookies = getCookies(domain);
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Clear cookies for a domain
  void clearCookies(String domain) {
    _cookies.remove(domain);
  }
}

/// Cookie item
class CookieItem {
  final String name;
  final String value;
  final String? domain;
  final DateTime? expires;

  const CookieItem({
    required this.name,
    required this.value,
    this.domain,
    this.expires,
  });
}
