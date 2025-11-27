import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_status.dart';

class ProgressService {
  static const String _storageKey = 'level_progress';
  static ProgressService? _instance;

  final Map<int, LevelStatus> _levelStatuses = {};
  SharedPreferences? _prefs;

  // Singleton pattern
  ProgressService._();

  static ProgressService get instance {
    _instance ??= ProgressService._();
    return _instance!;
  }

  // Initialize and load saved progress
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
  }

  // Load progress from storage
  Future<void> _loadProgress() async {
    final jsonString = _prefs?.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _levelStatuses.clear();
        jsonMap.forEach((key, value) {
          _levelStatuses[int.parse(key)] = LevelStatus.fromJson(value);
        });
      } catch (e) {
        print('Error loading progress: $e');
      }
    }
  }

  // Save progress to storage
  Future<void> _saveProgress() async {
    final Map<String, dynamic> jsonMap = {};
    _levelStatuses.forEach((key, value) {
      jsonMap[key.toString()] = value.toJson();
    });
    await _prefs?.setString(_storageKey, json.encode(jsonMap));
  }

  // Get all statuses
  Map<int, LevelStatus> getAllStatuses() {
    return Map.unmodifiable(_levelStatuses);
  }
  
  // Check if a level is completed successfully
  bool isCompleted(int levelNumber) {
    final s = _levelStatuses[levelNumber];
    return s != null && s.result == LevelResult.success;
  }

  // Return levels from the given ordered list that are not completed
  List<int> getUncompletedLevels(Iterable<int> orderedLevels) {
    final result = <int>[];
    for (final n in orderedLevels) {
      final s = _levelStatuses[n];
      if (s == null || s.result != LevelResult.success) {
        result.add(n);
      }
    }
    return result;
  }

  // Find the next uncompleted level after `afterLevel` within orderedLevels; wraps once.
  int? nextUncompletedLevel(Iterable<int> orderedLevels, int afterLevel) {
    final list = List<int>.from(orderedLevels);
    if (list.isEmpty) return null;
    final start = list.indexOf(afterLevel);
    if (start == -1) return null;
    // forward scan
    for (int i = start + 1; i < list.length; i++) {
      final n = list[i];
      final s = _levelStatuses[n];
      if (s == null || s.result != LevelResult.success) return n;
    }
    // wrap
    for (int i = 0; i < start; i++) {
      final n = list[i];
      final s = _levelStatuses[n];
      if (s == null || s.result != LevelResult.success) return n;
    }
    return null; // all completed
  }
  
  // Get level status
  LevelStatus? getLevelStatus(int levelNumber) {
    return _levelStatuses[levelNumber];
  }

  // Mark level as completed
  Future<void> completeLevel(int levelNumber, LevelResult result, Duration? completionTime) async {
    _levelStatuses[levelNumber] = LevelStatus(
      result: result,
      completionTime: completionTime,
    );
    await _saveProgress();
  }

  // Reset all progress
  Future<void> resetAllProgress() async {
    _levelStatuses.clear();
    await _saveProgress();
  }
}
