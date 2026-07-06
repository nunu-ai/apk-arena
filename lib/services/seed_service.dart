import 'dart:math';

class SeedService {
  SeedService._();
  static final SeedService instance = SeedService._();

  int? _activeSeed;

  int? get activeSeed => _activeSeed;

  void setSeedFromString(String? value) {
    if (value == null || value.isEmpty) {
      _activeSeed = null;
      return;
    }
    // Try numeric first, then fall back to string hash
    _activeSeed = int.tryParse(value) ?? value.hashCode;
  }

  Random createRandom() {
    final s = _activeSeed;
    return s != null ? Random(s) : Random();
  }
}
