import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/security/web_navigation_policy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';

/// Arguments for the in-app browser, passed via go_router `extra`.
class WebViewArgs {
  const WebViewArgs({required this.url, required this.title});
  final String url;
  final String title;
}

/// Lightweight in-app browser so external links (e.g. BscScan) open inside the
/// app instead of leaving it.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.args});

  final WebViewArgs args;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _hasError = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    final policy = WebNavigationPolicy.forUrl(widget.args.url);
    // A destination that fails the policy is never handed to the engine at
    // all, so a malformed or non-https link cannot load even once.
    if (policy == null) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Sub-resources (scripts, images, XHR) are left to the engine and
            // the page's own origin rules; only top-level navigation, the part
            // that can swap the site under the user, is gated here.
            if (!request.isMainFrame) return NavigationDecision.navigate;
            if (policy.allows(request.url)) return NavigationDecision.navigate;
            if (mounted) setState(() => _blocked = true);
            return NavigationDecision.prevent;
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onWebResourceError: (error) {
            // Only surface top-level failures, not sub-resource hiccups.
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _hasError = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.url));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = _controller;
    final loading = _progress < 100;
    return Scaffold(
      appBar: AppBar(
        leading: const MpcBackButton(fallbackRoute: '/'),
        title: Text(
          widget.args.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Reload',
              onPressed: controller.reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
        bottom: loading && controller != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(p.primary),
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: controller == null
            ? _BlockedView(
                url: widget.args.url,
                message:
                    'This link was blocked because it is not a secure (https) '
                    'address.',
              )
            : _hasError
            ? _ErrorView(
                url: widget.args.url,
                onRetry: () {
                  setState(() => _hasError = false);
                  controller.loadRequest(Uri.parse(widget.args.url));
                },
              )
            : Column(
                children: [
                  if (_blocked)
                    _BlockedBanner(
                      onDismiss: () => setState(() => _blocked = false),
                    ),
                  Expanded(child: WebViewWidget(controller: controller)),
                ],
              ),
      ),
    );
  }
}

/// Shown instead of the browser when the destination itself fails the policy.
class _BlockedView extends StatelessWidget {
  const _BlockedView({required this.url, required this.message});

  final String url;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 40, color: p.textLo),
            const SizedBox(height: 12),
            Text(
              'Link blocked',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textLo, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              url,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textLo, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notice for a redirect that tried to leave the site the browser was opened
/// for. Kept non-blocking: the original page stays usable underneath.
class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: p.textLo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This page tried to open another site. It was blocked.',
              style: TextStyle(color: p.textLo, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.url, required this.onRetry});
  final String url;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: p.textLo),
            const SizedBox(height: 12),
            Text(
              'Could not load the page',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              url,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textLo, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
