import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/deeplink_service.dart';
import '../../../level_registry.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelQrDeeplink extends LevelWidget {
  const LevelQrDeeplink({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelQrDeeplink> createState() => _LevelQrDeeplinkState();
}

class _LevelQrDeeplinkState extends State<LevelQrDeeplink> {
  final _rand = Random();
  late final String _token;
  late final String _url; // apkarena://level/qr?token=XYZ
  StreamSubscription? _sub;
  int? _qrLevelNumber;
  bool _consumed = false;

  @override
  void initState() {
    super.initState();
    _token = _generateToken();
    _qrLevelNumber = findLevelNumberByTitle('qr handshake');
    // Fallback to qr path if not found (shouldn't happen), but prefer numeric level link
    if (_qrLevelNumber != null) {
      _url = 'apkarena://open/level/${_qrLevelNumber}?token=$_token';
    } else {
      _url = 'apkarena://open/level/qr?token=$_token';
    }
    _listenLinks();
    // If a link already arrived before this screen mounted, try handling it
    final last = DeeplinkService.instance.takeLastUri();
    if (last != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeHandle(last));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[_rand.nextInt(chars.length)]).join();
  }

  void _listenLinks() async {
    await DeeplinkService.instance.initialize();
    try {
      final initial = await DeeplinkService.instance.getInitialLink();
      if (initial != null) _maybeHandle(initial);
    } catch (_) {}
    _sub = DeeplinkService.instance.linkStream.listen((uri) {
      _maybeHandle(uri);
    }, onError: (_) {});
  }

  void _maybeHandle(Uri uri) {
    if (_consumed) return;
    if (uri.scheme != 'apkarena') return;
    // support newer format: apkarena://open/level/<id>
    // also accept legacy host/path variants for robustness
    String? id;
    if (uri.host == 'open') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'level') {
        id = uri.pathSegments[1];
      } else {
        return;
      }
    } else if (uri.pathSegments.length >= 3 && uri.pathSegments[0] == 'open' && uri.pathSegments[1] == 'level') {
      id = uri.pathSegments[2];
    } else if (uri.host == 'level') {
      // legacy: apkarena://level/<id>
      if (uri.pathSegments.isEmpty) return;
      id = uri.pathSegments.first;
    } else if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'level' && uri.pathSegments.length >= 2) {
      // legacy: apkarena:/level/<id>
      id = uri.pathSegments[1];
    } else {
      return;
    }

    if (_qrLevelNumber != null) {
      final n = int.tryParse(id!);
      if (n != _qrLevelNumber) return; // not for this level
    } else if (id != 'qr') {
      return;
    }
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      // no token provided: open normally, do nothing
      DeeplinkService.instance.clearLastUri();
      return;
    }
    _consumed = true;
    _sub?.cancel();
    DeeplinkService.instance.clearLastUri();
    if (token == _token) {
      widget.onComplete(true);
    } else {
      widget.onComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: NunuColors.secondaryDark.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: NunuColors.secondaryMain.withOpacity(0.5), width: 2),
          ),
          child: QrImageView(
            data: _url,
            version: QrVersions.auto,
            size: 260,
            backgroundColor: NunuColors.backgroundPaper,
            // color the modules/eyes with secondary light for style
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: NunuColors.secondaryLight),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: NunuColors.secondaryLight),
          ),
        ),
      ),
    );
  }
}
