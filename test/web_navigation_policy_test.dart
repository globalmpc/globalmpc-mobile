import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/web_navigation_policy.dart';

/// The in-app browser is the one place the app renders content it does not
/// control. If any expectation here fails, a page the user opened can swap
/// itself for a phishing clone that asks for the recovery phrase.
void main() {
  group('entry URLs', () {
    test('accepts https destinations', () {
      expect(
        WebNavigationPolicy.forUrl('https://testnet.bscscan.com/tx/0xabc'),
        isNotNull,
      );
    });

    test('refuses cleartext and local-surface schemes', () {
      for (final url in [
        'http://testnet.bscscan.com',
        'javascript:alert(document.cookie)',
        'file:///etc/passwd',
        'data:text/html,<script>fetch("//x")</script>',
        'content://com.android.providers/x',
        'intent://scan/#Intent;scheme=x;end',
        'about:blank',
        'not a url at all',
        '',
      ]) {
        expect(
          WebNavigationPolicy.isSafeUrl(url),
          isFalse,
          reason: '$url must never be loaded',
        );
        expect(WebNavigationPolicy.forUrl(url), isNull);
      }
    });

    test('refuses https with no host', () {
      expect(WebNavigationPolicy.isSafeUrl('https:///path'), isFalse);
    });
  });

  group('navigation from an opened page', () {
    final policy = WebNavigationPolicy.forUrl(
      'https://testnet.bscscan.com/tx/0xabc',
    )!;

    test('allows the same site and its subdomains', () {
      expect(policy.allows('https://testnet.bscscan.com/address/0x1'), isTrue);
      expect(policy.allows('https://api.testnet.bscscan.com/x'), isTrue);
      expect(policy.allows('https://TESTNET.BSCSCAN.COM/x'), isTrue);
    });

    test('treats www as the same site', () {
      final apex = WebNavigationPolicy.forUrl('https://www.globalmpc.tech')!;

      expect(apex.allows('https://globalmpc.tech/blog'), isTrue);
      expect(apex.allows('https://www.globalmpc.tech/blog'), isTrue);
    });

    test('blocks lookalike domains that merely end in the same string', () {
      // The classic homograph/suffix trick: a substring check would pass all
      // of these, which is exactly how a clone gets rendered as the real site.
      for (final url in [
        'https://evil-testnet.bscscan.com.attacker.io/x',
        'https://testnet.bscscan.com.attacker.io/x',
        'https://nottestnet.bscscan.com/x'.replaceFirst(
          'nottestnet.bscscan.com',
          'faketestnet-bscscan.com',
        ),
        'https://bscscan.com.evil.co/x',
      ]) {
        expect(policy.allows(url), isFalse, reason: '$url must be blocked');
      }
    });

    test('blocks unrelated sites and downgrades to http', () {
      expect(policy.allows('https://phishing-mpc-wallet.io/seed'), isFalse);
      expect(policy.allows('http://testnet.bscscan.com/tx/0xabc'), isFalse);
      expect(policy.allows('javascript:void(0)'), isFalse);
    });

    test('blocks the parent domain of the opened host', () {
      // Pinning is to the host that was opened; widening to the registrable
      // domain would depend on a public-suffix list we do not ship.
      expect(policy.allows('https://bscscan.com/x'), isFalse);
    });
  });
}
