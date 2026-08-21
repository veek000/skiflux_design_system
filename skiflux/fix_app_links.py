import re

with open('lib/app/app.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add app_links import
text = text.replace('import \'package:firebase_messaging/firebase_messaging.dart\';', 'import \'package:app_links/app_links.dart\';\nimport \'package:firebase_messaging/firebase_messaging.dart\';')

# 2. Add _appLinks variable
text = text.replace('  var _fcmAttached = false;', '  var _fcmAttached = false;\n  var _appLinksAttached = false;\n  late AppLinks _appLinks;\n  StreamSubscription<Uri>? _appLinksSubscription;')

# 3. Add attachAppLinks call
text = text.replace('          WidgetsBinding.instance.addPostFrameCallback((_) {\n            unawaited(_attachFcm());\n          });', '          WidgetsBinding.instance.addPostFrameCallback((_) {\n            unawaited(_attachFcm());\n            unawaited(_attachAppLinks());\n          });')

# 4. Add dispose for subscription
text = text.replace('  @override\n  Widget build(BuildContext context) {', '  @override\n  void dispose() {\n    _appLinksSubscription?.cancel();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {')

# 5. Add _attachAppLinks method
attach_app_links_code = '''
  Future<void> _attachAppLinks() async {
    if (_appLinksAttached) return;
    _appLinksAttached = true;
    _appLinks = AppLinks();

    // Handle initial link (cold start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle background/foreground links
    _appLinksSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Expected format: https://app.skiflux.com/episode/<id> or https://skiflux.com/episode/<id>
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'episode' && uri.pathSegments.length > 1) {
      final episodeId = uri.pathSegments[1];
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      // You might need GoRouter or a custom navigator here to push the episode.
      // E.g. navContext.go('/episode/\');
      // For now we rely on the internal openNotificationDeepLink if it supports it, or simply parse it:
      unawaited(
        openNotificationDeepLink(
          navContext,
          ref,
          type: 'episode',
          data: {'id': episodeId, 'episode_id': episodeId},
        ),
      );
    }
  }
'''

text = text.replace('  Future<void> _maybeRegisterDevice(FcmService fcm) async {', attach_app_links_code + '\n  Future<void> _maybeRegisterDevice(FcmService fcm) async {')

with open('lib/app/app.dart', 'w', encoding='utf-8') as f:
    f.write(text)
