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