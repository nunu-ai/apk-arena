import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attempt_record.dart';

class AnalyticsService {
  static const String _dirName = 'nunu_artifacts';
  static const String _fileName = 'attempts.json';

  static AnalyticsService? _instance;
  List<AttemptRecord> _attempts = [];
  String? _filePath;

  AnalyticsService._();

  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  String? get filePath => _filePath;

  List<AttemptRecord> get attempts => List.unmodifiable(_attempts);

  Future<void> initialize() async {
    final storageDir = await _resolveStorageDirectory();
    _filePath = '${storageDir.path}/$_dirName/$_fileName';

    await _ensureDirectory();
    await _load();
  }

  Future<Directory> _resolveStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } on UnsupportedError {
        // Fall through to app documents storage.
      }
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _ensureDirectory() async {
    if (_filePath == null) return;
    final dir = File(_filePath!).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _load() async {
    if (_filePath == null) return;
    final file = File(_filePath!);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _attempts = jsonList
            .map((e) => AttemptRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error loading analytics: $e');
        _attempts = [];
      }
    }
  }

  Future<void> _save() async {
    if (_filePath == null) return;
    try {
      final file = File(_filePath!);
      final jsonList = _attempts.map((a) => a.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  Future<void> recordAttempt(AttemptRecord record) async {
    _attempts.add(record);
    await _save();
  }

  List<AttemptRecord> getAttemptsForLevel(int levelNumber) {
    return _attempts.where((a) => a.levelNumber == levelNumber).toList();
  }

  Future<String?> readFileContent() async {
    if (_filePath == null) return null;
    try {
      final file = File(_filePath!);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading analytics file: $e');
    }
    return null;
  }

  Future<void> clearAll() async {
    _attempts.clear();
    await _save();
  }
}
