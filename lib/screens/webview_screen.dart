import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// Displays static, locally-generated HTML in a WebView. Because the content is
/// loaded from a string (never the network), the app needs no INTERNET
/// permission and works fully offline.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.title, required this.html});

  const WebViewScreen.privacy({super.key})
      : title = 'Privacy Policy',
        html = _privacyHtml;

  const WebViewScreen.support({super.key})
      : title = 'Support',
        html = _supportHtml;

  final String title;
  final String html;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _bar(context),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.sky,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: AppColors.blueButton,
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: AppText.title(22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CircleIconButton(
            icon: Icons.close,
            size: 42,
            gradient: AppColors.goldButton,
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }
}

const String _htmlHead = '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, Roboto, Arial, sans-serif; color:#123; background:#ffffff;
         margin:0; padding:22px; line-height:1.55; }
  h1 { color:#0F6FB8; font-size:24px; }
  h2 { color:#0F6FB8; font-size:18px; margin-top:22px; }
  p, li { font-size:15px; color:#334; }
  .muted { color:#889; font-size:13px; }
</style></head><body>
''';

const String _privacyHtml = '''
$_htmlHead
<h1>Privacy Policy</h1>
<p class="muted">Last updated: 2026</p>
<p>Wingwhirl Run is a fully offline single-player game. This is a placeholder
privacy policy.</p>
<h2>Data We Collect</h2>
<p>We do not collect, store, or transmit any personal data. The game runs
entirely on your device and does not require an internet connection.</p>
<h2>Local Storage</h2>
<p>Your game progress (coins, collection and settings) is saved only on your
device using local storage.</p>
<h2>Third Parties</h2>
<p>The game contains no ads, no analytics and no third-party trackers.</p>
<h2>Contact</h2>
<p>For questions, please use the Support page inside the game.</p>
</body></html>
''';

const String _supportHtml = '''
$_htmlHead
<h1>Support</h1>
<p>Need help with Wingwhirl Run? This is a placeholder support page.</p>
<h2>Frequently Asked Questions</h2>
<p><b>How do I catch rare fish?</b><br>Upgrade your bait and rod, and unlock new
locations — rarer fish appear as you progress.</p>
<p><b>How do I get new chickens?</b><br>Open collectible eggs in the Shop.</p>
<p><b>Is an internet connection required?</b><br>No. The game is fully playable
offline.</p>
<h2>Contact</h2>
<p>Support URL: <span class="muted">https://example.com/support</span></p>
<p class="muted">(Placeholder — replace with your real support link before
release.)</p>
</body></html>
''';
