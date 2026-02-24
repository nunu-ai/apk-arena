import 'dart:async';
import 'package:flutter/services.dart';

class DeeplinkService {
  DeeplinkService._();
  static final DeeplinkService instance = DeeplinkService._();

  static const MethodChannel _channel = MethodChannel('apkarena/links');

  final StreamController<Uri> _controller = StreamController.broadcast();
  Stream<Uri> get linkStream => _controller.stream;

  Uri? lastUri; // retains most recent link (initial or runtime)

  bool _initialized = false;
  bool _channelUnavailable = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final String? s = call.arguments as String?;
        if (s != null) {
          final uri = Uri.tryParse(s);
          if (uri != null) {
            lastUri = uri;
            _controller.add(uri);
          }
        }
      }
    });
  }

  Future<Uri?> getInitialLink() async {
    if (_channelUnavailable) return null;
    try {
      final String? s = await _channel.invokeMethod<String>('getInitialLink');
      if (s == null) return null;
      final uri = Uri.tryParse(s);
      if (uri != null) lastUri = uri;
      return uri;
    } on MissingPluginException {
      _channelUnavailable = true;
      return null;
    } on PlatformException {
      _channelUnavailable = true;
      return null;
    }
  }

  // Returns and clears the last stored URI, so it won't be reprocessed.
  Uri? takeLastUri() {
    final u = lastUri;
    lastUri = null;
    return u;
  }

  void clearLastUri() {
    lastUri = null;
  }
}
