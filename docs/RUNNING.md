# Running APK Arena

This page covers installing the app, controlling it programmatically from your agent harness via deeplinks, and extracting benchmark results from the artifact file.

---

## Installation

On android simply do
```bash
adb install apk_arena.apk
```

---

## Deeplinks

APK Arena uses a custom URI scheme (`apkarena://`) so your evaluation setup can open a level directly.

| Intent | URI |
|---|---|
| Open a specific level | `apkarena://open/level/42` |
| Open a random level | `apkarena://open/random` |
| Open a random level (explicit) | `apkarena://open/level/random` |

Append these to any URI:

| Parameter | Description | Example |
|---|---|---|
| `attempts` | Limit the number of attempts for this run. The level closes after N completions. | `?attempts=1` |
| `seed` | Fix the RNG seed so randomised levels are reproducible across agents. | `?seed=abc123` |

Full example:

```
apkarena://open/level/42?attempts=1&seed=abc123
```

## Result Artifacts

After each completed level run the app appends a record to a JSON file on the device. Your evaluation harness can pull this file to automatically get scores and do post processing.

### File location

**Android:**
```
/storage/emulated/0/Android/data/com.example.apk_arena/files/nunu_artifacts/attempts.json
```

**iOS:** the file is in the app's Documents folder and can be accessed via the Files app or `xcrun simctl` on the simulator.

### Pulling the file (Android)

```bash
adb pull \
  /storage/emulated/0/Android/data/com.example.apk_arena/files/nunu_artifacts/attempts.json \
  attempts.json
```

### Record schema

Each entry in the JSON array is one completed level run:

```json
{
  "levelNumber": 42,
  "levelTitle": "Better Call Saul",
  "category": "tasks",
  "timestamp": "2025-07-06T14:23:01.123Z",
  "success": true,
  "score": 0.85,
  "durationMs": 34200,
  "metrics": {
    "wrong_taps": 2
  }
}
```

| Field | Type | Description |
|---|---|---|
| `levelNumber` | int | Level ID |
| `levelTitle` | string | Display name of the level |
| `category` | string | Category slug (primitives, vision, memory, iq, tempospatial, games, tasks) |
| `timestamp` | string | ISO 8601 completion time |
| `success` | bool | `true` when `score >= 1.0` |
| `score` | float | 0–1, where 1 is a perfect run |
| `durationMs` | int | Wall-clock time from level start to completion |
| `metrics` | object? | Level-specific diagnostic numbers (moves, wrong_answers, etc.) — present only when the level exposes them |
