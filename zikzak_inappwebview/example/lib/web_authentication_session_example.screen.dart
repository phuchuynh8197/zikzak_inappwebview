import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';
import 'package:logging/logging.dart';

import 'main.dart';

class WebAuthenticationSessionExampleScreen extends StatefulWidget {
  const WebAuthenticationSessionExampleScreen({super.key});

  @override
  WebAuthenticationSessionExampleScreenState createState() =>
      WebAuthenticationSessionExampleScreenState();
}

class WebAuthenticationSessionExampleScreenState
    extends State<WebAuthenticationSessionExampleScreen> {
  WebAuthenticationSession? session;
  String? token;
  final _logger = Logger('WebAuthenticationSessionExampleScreen');

  @override
  void dispose() {
    session?.dispose();
    super.dispose();
  }

  Future<void> _createWebAuthSession() async {
    if (session != null ||
        kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.macOS]
            .contains(defaultTargetPlatform) ||
        !await WebAuthenticationSession.isAvailable()) {
      _logger.warning('Cannot create Web Authentication Session');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot create Web Authentication Session!'),
        ));
      }
      return;
    }

    try {
      session = await WebAuthenticationSession.create(
          url: WebUri("http://localhost:8080/web-auth.html"),
          callbackURLScheme: "test",
          onComplete: (url, error) {
            if (url != null) {
              setState(() {
                token = url.queryParameters["token"];
              });
            } else if (error != null) {
              _logger.warning('Web Authentication error: $error');
            }
            return Future<
                void>.value(); // Add this line to return a Future<void>
          });
      setState(() {});
    } catch (e) {
      _logger.severe('Error creating Web Authentication Session: $e');
    }
  }

  Future<void> _startWebAuthSession() async {
    try {
      if (await session?.canStart() ?? false) {
        final started = await session?.start() ?? false;
        if (!started) {
          _logger.warning('Cannot start Web Authentication Session');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cannot start Web Authentication Session!'),
            ));
          }
        } else {
          _logger.info('Web Authentication Session started successfully');
        }
      } else {
        _logger.warning('Session cannot start');
      }
    } catch (e) {
      _logger.severe('Error starting Web Authentication Session: $e');
    }
  }

  void _disposeWebAuthSession() {
    try {
      session?.dispose();
      setState(() {
        token = null;
        session = null;
      });
      _logger.info('Web Authentication Session disposed');
    } catch (e) {
      _logger.severe('Error disposing Web Authentication Session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text(
          "WebAuthenticationSession",
        )),
        drawer: myDrawer(context: context),
        body: SafeArea(
          child: Column(children: <Widget>[
            Center(
                child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Text("Token: $token"),
            )),
            if (session == null)
              Center(
                child: ElevatedButton(
                    onPressed: _createWebAuthSession,
                    child: const Text("Create Web Auth Session")),
              )
            else ...[
              Center(
                child: ElevatedButton(
                    onPressed: _startWebAuthSession,
                    child: const Text("Start Web Auth Session")),
              ),
              Center(
                child: ElevatedButton(
                    onPressed: _disposeWebAuthSession,
                    child: const Text("Dispose Web Auth Session")),
              )
            ],
          ]),
        ));
  }
}
