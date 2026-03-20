import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/utils/packages/graphify/controller/graphify_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/resources/dependencies.js.dart';
import 'package:app_saku_rapi/utils/packages/graphify/resources/index.html.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/console_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class GraphifyView extends StatefulWidget {
  const GraphifyView({
    super.key,
    this.controller,
    this.initialOptions,
    this.onConsoleMessage,
    this.onCreated,
    this.isDarkMode = false,
  });

  final GraphifyController? controller;

  final Map<String, dynamic>? initialOptions;

  final OnConsoleMessage? onConsoleMessage;

  final VoidCallback? onCreated;
  final bool isDarkMode;

  @override
  State<StatefulWidget> createState() => _GraphifyViewState();
}

class _GraphifyViewState extends State<GraphifyView> {
  late final WebViewController webViewController;
  late final controller = (widget.controller ?? GraphifyController());
  late Widget view;

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController wdController =
        WebViewController.fromPlatformCreationParams(params);

    if (wdController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (wdController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    webViewController = wdController;
    initView();
    buildView();
  }

  void initView() {
    controller.connector = webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setOnConsoleMessage(
        widget.onConsoleMessage ??
            (val) {
              AppLogger.call('GraphifyView console: ${val.message}');
            },
      )
      ..loadHtmlString(
        indexHtml(
          id: controller.uid,
          dependencies: '<script>$dependencies</script>',
          isDarkMode: widget.isDarkMode,
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            widget.onCreated?.call();
            controller.update(widget.initialOptions);
          },
        ),
      );
  }

  Widget buildView() {
    return view = WebViewWidget(
      controller: webViewController,
      gestureRecognizers: {
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
        Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      },
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller.dispose();
    }
    webViewController
      ..clearLocalStorage()
      ..clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => view;
}
