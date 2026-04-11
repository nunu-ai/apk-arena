import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_outcome.dart';
import '../models/level_status.dart';

class ProgressService {
  static const String _storageKey = 'level_progress';
  static ProgressService? _instance;

  final Map<int, LevelStatus> _levelStatuses = {};
  SharedPreferences? _prefs;

  ProgressService._();

  static ProgressService get instance {
    _instance ??= ProgressService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
  }

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

  Future<void> _saveProgress() async {
    final Map<String, dynamic> jsonMap = {};
    _levelStatuses.forEach((key, value) {
      jsonMap[key.toString()] = value.toJson();
    });
    await _prefs?.setString(_storageKey, json.encode(jsonMap));
  }

  Map<int, LevelStatus> getAllStatuses() {
    return Map.unmodifiable(_levelStatuses);
  }

  LevelStatus? getLevelStatus(int levelNumber) {
    return _levelStatuses[levelNumber];
  }

  /// Updates monotonic best score and duration-at-best when the score improves or ties faster.
  Future<void> recordLevelFinish(
    int levelNumber,
    LevelOutcome outcome,
    Duration elapsed,
  ) async {
    final prev = _levelStatuses[levelNumber];
    final prevBest = prev?.bestScore;
    final newScore = outcome.score;

    final double updatedBest;
    if (prevBest == null) {
      updatedBest = newScore;
    } else if (newScore > prevBest) {
      updatedBest = newScore;
    } else {
      updatedBest = prevBest;
    }

    int? newDurAtBest = prev?.durationMsAtBest;
    final elapsedMs = elapsed.inMilliseconds;

    if (prevBest == null) {
      newDurAtBest = elapsedMs;
    } else if (newScore > prevBest) {
      newDurAtBest = elapsedMs;
    } else if (newScore == prevBest) {
      if (newDurAtBest == null || elapsedMs < newDurAtBest) {
        newDurAtBest = elapsedMs;
      }
    }

    _levelStatuses[levelNumber] = LevelStatus(
      bestScore: updatedBest,
      durationMsAtBest: newDurAtBest,
    );
    await _saveProgress();
  }

  Future<void> resetAllProgress() async {
    _levelStatuses.clear();
    await _saveProgress();
  }
}
