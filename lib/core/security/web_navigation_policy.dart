/// Navigation allowlist for the in-app browser (spec S8).
///
/// A wallet that will follow any link it is handed is a phishing delivery
/// mechanism: the classic attack is a legitimate-looking explorer page that
/// redirects to a clone asking for the recovery phrase. The in-app browser is
/// therefore pinned to the site it was opened for — the user can browse
/// BscScan, but BscScan cannot bounce them somewhere else.
///
/// The rule is deliberately strict (same host or a subdomain of it). A blocked
/// legitimate redirect surfaces as a visible "link blocked" notice, which is a
/// safe failure; a permissive rule fails silently and invisibly.
class WebNavigationPolicy {
  WebNavigationPolicy._(this._baseHost);

  /// Builds a policy pinned to [url]'s host, or null when [url] is not a
  /// valid https destination and so must not be opened at all.
  static WebNavigationPolicy? forUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !isSafeUrl(url)) return null;
    return WebNavigationPolicy._(_normalizeHost(uri.host));
  }

  final String _baseHost;

  /// Only plain https destinations are ever loaded. This rejects `http`
  /// (cleartext), and the schemes that turn a browser into a local attack
  /// surface: `javascript:`, `file:`, `data:`, `content:`, `intent:`.
  static bool isSafeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme.toLowerCase() == 'https' && uri.host.isNotEmpty;
  }

  /// Whether a main-frame navigation to [url] may proceed.
  bool allows(String url) {
    if (!isSafeUrl(url)) return false;
    final host = _normalizeHost(Uri.parse(url).host);
    return host == _baseHost || host.endsWith('.$_baseHost');
  }

  /// Lowercases and drops a leading `www.`, so an apex/www redirect on the
  /// same site is not treated as leaving it.
  static String _normalizeHost(String host) {
    final lower = host.toLowerCase();
    return lower.startsWith('www.') ? lower.substring(4) : lower;
  }
}
