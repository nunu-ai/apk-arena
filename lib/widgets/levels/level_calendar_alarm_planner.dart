import 'package:flutter/material.dart';

import 'package:apk_arena/models/level_outcome.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelCalendarAlarmPlanner extends LevelWidget {
  const LevelCalendarAlarmPlanner({super.key, required super.onComplete});

  @override
  State<LevelCalendarAlarmPlanner> createState() =>
      _LevelCalendarAlarmPlannerState();
}

class _LevelCalendarAlarmPlannerState extends State<LevelCalendarAlarmPlanner> {
  static const List<String> _dayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<int> _snoozeOptions = [0, 5, 10, 15];
  static const double _hourRowHeight = 68;

  late final _PlannerScenario _scenario;
  late final List<DateTime> _days;
  late List<_PlannerAlarm> _alarms;
  final ScrollController _weekScrollController = ScrollController();
  int _tabIndex = 0;
  int _dayIndex = 0;
  bool _submitted = false;
  bool _showWeekFadeLeft = false;
  bool _showWeekFadeRight = true;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _evaluate().score));
    _scenario = _buildScenario();
    _days = _collectDays(_scenario.visibleWeek);
    _alarms = _scenario.initialAlarms.map((alarm) => alarm.copy()).toList();
    _weekScrollController.addListener(_updateWeekStripFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateWeekStripFades();
    });
  }

  @override
  void dispose() {
    _weekScrollController.removeListener(_updateWeekStripFades);
    _weekScrollController.dispose();
    super.dispose();
  }

  _PlannerScenario _buildScenario() {
    final march2 = DateTime(2026, 3, 2);
    final march3 = DateTime(2026, 3, 3);
    final march4 = DateTime(2026, 3, 4);
    final march5 = DateTime(2026, 3, 5);
    final march6 = DateTime(2026, 3, 6);
    final march7 = DateTime(2026, 3, 7);
    final march8 = DateTime(2026, 3, 8);

    return _PlannerScenario(
      events: [
        _PlannerEvent(
          id: 'os-lecture-mon',
          title: 'operating systems lecture',
          location: 'eng hall 240',
          note: 'slides already downloaded, front row if you beat marco there',
          start: DateTime(2026, 3, 2, 9, 0),
          duration: const Duration(hours: 1, minutes: 15),
          color: const Color(0xFF6366F1),
          recurrenceLabel: 'every mon, wed, fri',
        ),
        _PlannerEvent(
          id: 'study-session-mon',
          title: 'distributed systems study session',
          location: 'main library',
          note: 'whiteboard room booked under jina',
          start: DateTime(2026, 3, 2, 19, 0),
          duration: const Duration(hours: 2),
          color: const Color(0xFF14B8A6),
        ),
        _PlannerEvent(
          id: 'warehouse-shift',
          title: 'warehouse shift',
          location: 'pier 8',
          note:
              'badge check at 7:50. out the door by 7:35 if you want coffee first.',
          start: DateTime(2026, 3, 3, 8, 0),
          duration: const Duration(hours: 8),
          color: const Color(0xFF3B82F6),
          recurrenceLabel: 'every weekday',
        ),
        _PlannerEvent(
          id: 'lunch-supervisor',
          title: 'lunch with supervisor',
          location: 'student union cafe',
          note: 'be at the north campus stop by 11:40 for the shuttle, otherwise you are late',
          start: DateTime(2026, 3, 3, 12, 15),
          duration: const Duration(hours: 1),
          color: const Color(0xFFEC4899),
        ),
        _PlannerEvent(
          id: 'climbing-practice-tue',
          title: 'climbing practice',
          location: 'rec center wall',
          note: 'leave the lab by 6:30. shoes are already in your bag.',
          start: DateTime(2026, 3, 3, 19, 0),
          duration: const Duration(hours: 1, minutes: 30),
          color: const Color(0xFF22C55E),
          recurrenceLabel: 'every tue, thu',
        ),
        _PlannerEvent(
          id: 'os-lecture-wed',
          title: 'operating systems lecture',
          location: 'eng hall 240',
          note: 'quiz section today, do not drift in after start',
          start: DateTime(2026, 3, 4, 9, 0),
          duration: const Duration(hours: 1, minutes: 15),
          color: const Color(0xFF6366F1),
          recurrenceLabel: 'every mon, wed, fri',
        ),
        _PlannerEvent(
          id: 'design-review',
          title: 'design review',
          location: 'building c / floor 2',
          note: 'need a 15-minute heads-up to get across campus from the lab',
          start: DateTime(2026, 3, 4, 13, 30),
          duration: const Duration(minutes: 45),
          color: const Color(0xFF10B981),
        ),
        _PlannerEvent(
          id: 'friend-dinner-wed',
          title: 'dinner with friends',
          location: 'ramen station',
          note: 'kai booked for 7:30, text if you are running late',
          start: DateTime(2026, 3, 4, 19, 30),
          duration: const Duration(hours: 1, minutes: 30),
          color: const Color(0xFFF97316),
        ),
        _PlannerEvent(
          id: 'systems-midterm',
          title: 'systems midterm',
          location: 'science center 101',
          note:
              'do the panic stack: 7:00 / 7:05 / 7:10. exam doors lock at 8:30.',
          start: DateTime(2026, 3, 5, 9, 0),
          duration: const Duration(hours: 2),
          color: const Color(0xFFEF4444),
        ),
        _PlannerEvent(
          id: 'package-dropoff',
          title: 'post office drop-off',
          location: 'campus mail center',
          note: 'mail room shutters at 5. last safe leave time is 4:10.',
          start: DateTime(2026, 3, 5, 16, 40),
          duration: const Duration(minutes: 20),
          color: const Color(0xFF84CC16),
        ),
        _PlannerEvent(
          id: 'climbing-practice-thu',
          title: 'climbing practice',
          location: 'rec center wall',
          note: 'same drill as tuesday, leave the lab by 6:30.',
          start: DateTime(2026, 3, 5, 19, 0),
          duration: const Duration(hours: 1, minutes: 30),
          color: const Color(0xFF22C55E),
          recurrenceLabel: 'every tue, thu',
        ),
        _PlannerEvent(
          id: 'os-lecture-fri',
          title: 'operating systems lecture',
          location: 'eng hall 240',
          note: 'last lecture before project groups get assigned',
          start: DateTime(2026, 3, 6, 9, 0),
          duration: const Duration(hours: 1, minutes: 15),
          color: const Color(0xFF6366F1),
          recurrenceLabel: 'every mon, wed, fri',
        ),
        _PlannerEvent(
          id: 'laundry',
          title: 'laundry pickup',
          location: 'residence hall basement',
          note:
              'washers finish at 5:25. if you forget again, your clothes are gone.',
          start: DateTime(2026, 3, 6, 17, 25),
          duration: const Duration(minutes: 20),
          color: const Color(0xFF06B6D4),
        ),
        _PlannerEvent(
          id: 'soccer',
          title: 'intramural soccer',
          location: 'north field',
          note: 'captain says warmups start at 5:20 sharp',
          start: DateTime(2026, 3, 6, 17, 30),
          duration: const Duration(hours: 1, minutes: 30),
          color: const Color(0xFF16A34A),
        ),
        _PlannerEvent(
          id: 'sleep-study',
          title: 'sleep study check-in',
          location: 'north clinic',
          note:
              'be out the door by 7:50 for the cab. miss intake and they give your slot away.',
          start: DateTime(2026, 3, 7, 9, 0),
          duration: const Duration(minutes: 30),
          color: const Color(0xFFF59E0B),
        ),
        _PlannerEvent(
          id: 'remote-retro',
          title: 'remote retro',
          location: 'video call',
          note: 'camera on this week because the PM is joining',
          start: DateTime(2026, 3, 7, 16, 0),
          duration: const Duration(minutes: 30),
          color: const Color(0xFF8B5CF6),
        ),
        _PlannerEvent(
          id: 'half-life-stream',
          title: 'half-life 3 reveal stream',
          location: 'dorm room',
          note: 'clear the evening and be online before spoilers hit the group chat',
          start: DateTime(2026, 3, 7, 21, 0),
          duration: const Duration(hours: 2),
          color: const Color(0xFFDC2626),
        ),
        _PlannerEvent(
          id: 'family-lunch',
          title: 'family lunch',
          location: 'parents\' place',
          note: 'leave by 11:35 if traffic is normal. grandma hates late arrivals.',
          start: DateTime(2026, 3, 8, 12, 30),
          duration: const Duration(hours: 2),
          color: const Color(0xFFF97316),
        ),
      ],
      initialAlarms: [
        _PlannerAlarm(
          id: 'warehouse-alarm',
          label: 'warehouse shift',
          time: const TimeOfDay(hour: 7, minute: 30),
          repeatDays: {0, 1, 2, 3, 4},
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'climbing-alarm',
          label: 'climbing practice',
          time: const TimeOfDay(hour: 18, minute: 45),
          repeatDays: {1, 3},
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'soccer-alarm',
          label: 'soccer',
          time: const TimeOfDay(hour: 17, minute: 0),
          repeatDays: const <int>{},
          oneTimeDate: march6,
          enabled: false,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'sleep-study-alarm',
          label: 'sleep study',
          time: const TimeOfDay(hour: 8, minute: 0),
          repeatDays: const <int>{},
          oneTimeDate: march7,
          enabled: false,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'stale-alarm',
          label: 'wake up',
          time: const TimeOfDay(hour: 6, minute: 45),
          repeatDays: {0, 1, 2, 3, 4},
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'family-lunch-old',
          label: 'family lunch',
          time: const TimeOfDay(hour: 12, minute: 0),
          repeatDays: const <int>{},
          oneTimeDate: march8,
          enabled: true,
          snoozeMinutes: 10,
        ),
      ],
      expectedAlarms: [
        _PlannerAlarm(
          id: 'expected-warehouse',
          label: 'warehouse shift',
          time: const TimeOfDay(hour: 7, minute: 35),
          repeatDays: {0, 1, 2, 3, 4},
          enabled: true,
          snoozeMinutes: 0,
        ),
        _PlannerAlarm(
          id: 'expected-supervisor',
          label: 'lunch with supervisor',
          time: const TimeOfDay(hour: 11, minute: 40),
          repeatDays: const <int>{},
          oneTimeDate: march3,
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-climbing',
          label: 'climbing practice',
          time: const TimeOfDay(hour: 18, minute: 30),
          repeatDays: {1, 3},
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-design',
          label: 'design review',
          time: const TimeOfDay(hour: 13, minute: 15),
          repeatDays: const <int>{},
          oneTimeDate: march4,
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-midterm-1',
          label: 'systems midterm',
          time: const TimeOfDay(hour: 7, minute: 0),
          repeatDays: const <int>{},
          oneTimeDate: march5,
          enabled: true,
          snoozeMinutes: 0,
        ),
        _PlannerAlarm(
          id: 'expected-midterm-2',
          label: 'systems midterm',
          time: const TimeOfDay(hour: 7, minute: 5),
          repeatDays: const <int>{},
          oneTimeDate: march5,
          enabled: true,
          snoozeMinutes: 0,
        ),
        _PlannerAlarm(
          id: 'expected-midterm-3',
          label: 'systems midterm',
          time: const TimeOfDay(hour: 7, minute: 10),
          repeatDays: const <int>{},
          oneTimeDate: march5,
          enabled: true,
          snoozeMinutes: 0,
        ),
        _PlannerAlarm(
          id: 'expected-post-office',
          label: 'post office',
          time: const TimeOfDay(hour: 16, minute: 10),
          repeatDays: const <int>{},
          oneTimeDate: march5,
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-laundry',
          label: 'laundry',
          time: const TimeOfDay(hour: 17, minute: 25),
          repeatDays: const <int>{},
          oneTimeDate: march6,
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-soccer',
          label: 'soccer',
          time: const TimeOfDay(hour: 17, minute: 20),
          repeatDays: const <int>{},
          oneTimeDate: march6,
          enabled: true,
          snoozeMinutes: 10,
        ),
        _PlannerAlarm(
          id: 'expected-sleep-study',
          label: 'sleep study',
          time: const TimeOfDay(hour: 7, minute: 50),
          repeatDays: const <int>{},
          oneTimeDate: march7,
          enabled: true,
          snoozeMinutes: 0,
        ),
        _PlannerAlarm(
          id: 'expected-family-lunch',
          label: 'family lunch',
          time: const TimeOfDay(hour: 11, minute: 35),
          repeatDays: const <int>{},
          oneTimeDate: march8,
          enabled: true,
          snoozeMinutes: 10,
        ),
      ],
      visibleWeek: [
        march2,
        march3,
        march4,
        march5,
        march6,
        march7,
        march8,
      ],
    );
  }

  List<DateTime> _collectDays(List<DateTime> daysInput) {
    final seen = <String>{};
    final days = <DateTime>[];
    for (final input in daysInput) {
      final day = DateTime(input.year, input.month, input.day);
      final key = '${day.year}-${day.month}-${day.day}';
      if (seen.add(key)) days.add(day);
    }
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  List<_PlannerEvent> _eventsForDay(DateTime day) {
    return _scenario.events
        .where(
          (event) =>
              event.start.year == day.year &&
              event.start.month == day.month &&
              event.start.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void _updateWeekStripFades() {
    if (!_weekScrollController.hasClients) return;
    final position = _weekScrollController.position;
    final left = position.pixels > 4;
    final right = position.pixels < position.maxScrollExtent - 4;
    if (left != _showWeekFadeLeft || right != _showWeekFadeRight) {
      setState(() {
        _showWeekFadeLeft = left;
        _showWeekFadeRight = right;
      });
    }
  }

  Future<void> _showEventSheet(_PlannerEvent event) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 72,
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatEventDay(event.start),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTime(TimeOfDay.fromDateTime(event.start))} - ${_formatTime(TimeOfDay.fromDateTime(event.start.add(event.duration)))}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sheetRow(Icons.place_outlined, event.location),
                if (event.recurrenceLabel != null) ...[
                  const SizedBox(height: 14),
                  _sheetRow(Icons.repeat, event.recurrenceLabel!),
                ],
                const SizedBox(height: 14),
                _sheetRow(Icons.sticky_note_2_outlined, event.note),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTimeFor({
    required TimeOfDay current,
    required void Function(TimeOfDay time) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey.shade900,
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: NunuColors.primaryMain,
              dialBackgroundColor: Colors.grey.shade800,
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? NunuColors.primaryMain
                    : Colors.grey.shade800,
              ),
              dayPeriodColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? NunuColors.primaryMain
                    : Colors.grey.shade800,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: NunuColors.primaryMain,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _openAlarmEditor({_PlannerAlarm? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    TimeOfDay selectedTime = existing?.time ?? const TimeOfDay(hour: 7, minute: 0);
    bool enabled = existing?.enabled ?? true;
    int snoozeMinutes = existing?.snoozeMinutes ?? 10;
    bool repeats = existing?.oneTimeDate == null;
    DateTime selectedDate = existing?.oneTimeDate ?? _days.first;
    final selectedDays = <int>{
      ...(existing?.repeatDays ?? (existing == null ? {0, 1, 2, 3, 4} : const <int>{})),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade900,
                        Colors.black,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('cancel'),
                            ),
                            const Spacer(),
                            Text(
                              existing == null ? 'new alarm' : 'edit alarm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                final alarmName = labelController.text.trim();
                                if (alarmName.isEmpty) return;
                                if (repeats && selectedDays.isEmpty) return;
                                final updated = _PlannerAlarm(
                                  id: existing?.id ??
                                      'alarm-${DateTime.now().microsecondsSinceEpoch}',
                                  label: alarmName,
                                  time: selectedTime,
                                  repeatDays: repeats
                                      ? {...selectedDays}
                                      : const <int>{},
                                  oneTimeDate: repeats ? null : selectedDate,
                                  enabled: enabled,
                                  snoozeMinutes: snoozeMinutes,
                                );
                                setState(() {
                                  if (existing == null) {
                                    _alarms.add(updated);
                                  } else {
                                    final index = _alarms.indexWhere(
                                      (alarm) => alarm.id == existing.id,
                                    );
                                    if (index != -1) _alarms[index] = updated;
                                  }
                                  _sortAlarms();
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('done'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickTimeFor(
                            current: selectedTime,
                            onPicked: (time) =>
                                setSheetState(() => selectedTime = time),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(selectedTime),
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  color: NunuColors.primaryMain,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: labelController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'alarm name',
                            hintText: 'alarm name',
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'repeat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: repeats,
                                    onChanged: (value) {
                                      setSheetState(() {
                                        repeats = value;
                                        if (repeats && selectedDays.isEmpty) {
                                          selectedDays.addAll({0, 1, 2, 3, 4});
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (!repeats) ...[
                                const SizedBox(height: 6),
                                DropdownButtonFormField<DateTime>(
                                  value: selectedDate,
                                  decoration:
                                      const InputDecoration(labelText: 'date'),
                                  dropdownColor: NunuColors.backgroundPaper,
                                  items: _days
                                      .map(
                                        (day) => DropdownMenuItem<DateTime>(
                                          value: day,
                                          child: Text(_formatEventDay(day)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setSheetState(() => selectedDate = value);
                                    }
                                  },
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'repeat',
                                    style: TextStyle(
                                      color: NunuColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(7, (index) {
                                    final selected =
                                        selectedDays.contains(index);
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          if (selected) {
                                            selectedDays.remove(index);
                                          } else {
                                            selectedDays.add(index);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? NunuColors.primaryMain
                                              : Colors.grey.shade800,
                                          border: Border.all(
                                            color: selected
                                                ? NunuColors.primaryMain
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _dayShort[index],
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.white60,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _editorRow(
                                title: 'snooze',
                                trailing: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: snoozeMinutes,
                                    dropdownColor: NunuColors.backgroundPaper,
                                    style: const TextStyle(color: Colors.white),
                                    items: _snoozeOptions
                                        .map(
                                          (minutes) => DropdownMenuItem<int>(
                                            value: minutes,
                                            child: Text(
                                              minutes == 0
                                                  ? 'off'
                                                  : '$minutes minutes',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setSheetState(
                                          () => snoozeMinutes = value,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 16),
                              _editorRow(
                                title: 'alarm enabled',
                                trailing: Switch(
                                  value: enabled,
                                  onChanged: (value) {
                                    setSheetState(() => enabled = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (existing != null) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _alarms.removeWhere(
                                  (alarm) => alarm.id == existing.id,
                                );
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'delete alarm',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
  }

  Widget _editorRow({required String title, required Widget trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aValue = a.time.hour * 60 + a.time.minute;
      final bValue = b.time.hour * 60 + b.time.minute;
      return aValue.compareTo(bValue);
    });
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final evaluation = _evaluate();
    widget.onComplete(
      LevelOutcome(score: evaluation.score, metrics: evaluation.metrics),
    );
  }

  _Evaluation _evaluate() {
    final remaining = _alarms.map((alarm) => alarm.copy()).toList();
    var totalEarned = 0.0;
    var correct = 0;
    var missing = 0;

    for (final expected in _scenario.expectedAlarms) {
      var bestIndex = -1;
      var bestScore = -1.0;

      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        if (!_labelMatches(candidate.label, expected.label)) continue;
        final score = _matchScore(candidate, expected);
        if (score > bestScore) {
          bestScore = score;
          bestIndex = i;
        }
      }

      if (bestIndex == -1) {
        missing++;
        continue;
      }
      totalEarned += bestScore;
      if (bestScore >= 0.9) correct++;
      remaining.removeAt(bestIndex);
    }

    final extra = remaining.length;
    final totalExpected = _scenario.expectedAlarms.length.toDouble();
    final baseScore = totalExpected == 0 ? 0.0 : totalEarned / totalExpected;
    final extraPenalty =
        totalExpected == 0 ? 0.0 : (extra / totalExpected) * 0.08;
    final score = (baseScore - extraPenalty).clamp(0.0, 1.0);

    return _Evaluation(
      score: score,
      metrics: {
        'correct': correct,
        'missing': missing,
        'extra': extra,
      },
    );
  }

  double _matchScore(_PlannerAlarm actual, _PlannerAlarm expected) {
    if (expected.enabled && !actual.enabled) return 0.0;
    final time = _timeScore(actual.time, expected.time);
    final scheduleMatch = expected.oneTimeDate != null
        ? (_sameDate(actual.oneTimeDate, expected.oneTimeDate) ? 1.0 : 0.0)
        : (_sameDays(actual.repeatDays, expected.repeatDays) ? 1.0 : 0.0);
    return time * 0.6 + scheduleMatch * 0.4;
  }

  double _timeScore(TimeOfDay actual, TimeOfDay expected) {
    final actualMinutes = actual.hour * 60 + actual.minute;
    final expectedMinutes = expected.hour * 60 + expected.minute;
    final diff = actualMinutes - expectedMinutes;
    if (diff > 5) return 0.0;
    if (diff >= -15) return 1.0;
    if (diff >= -30) return 0.5;
    return 0.0;
  }

  bool _labelMatches(String a, String b) {
    final na = _normalize(a);
    final nb = _normalize(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;
    final tokensA =
        na.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    final tokensB =
        nb.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    if (tokensA.isEmpty || tokensB.isEmpty) return false;
    final overlap = tokensA.intersection(tokensB).length;
    final minSize = tokensA.length < tokensB.length ? tokensA.length : tokensB.length;
    return overlap >= (minSize / 2).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FA),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopTabs(),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildCalendarApp(),
                  _buildAlarmApp(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _AppTab(
              label: 'calendar',
              icon: Icons.calendar_today,
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AppTab(
              label: 'clock',
              icon: Icons.alarm,
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarApp() {
    final day = _days[_dayIndex];
    final events = _eventsForDay(day);

    return Container(
      color: const Color(0xFFF4F6FA),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu, color: Colors.black87),
                    SizedBox(width: 12),
                    Text(
                      'March',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.search, color: Colors.black87),
                    SizedBox(width: 12),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF2563EB),
                      child: Text(
                        'A',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 68,
                  child: Stack(
                    children: [
                      ListView.separated(
                        controller: _weekScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _scenario.visibleWeek.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final itemDay = _scenario.visibleWeek[index];
                          final selected = _sameDate(itemDay, day);
                          return GestureDetector(
                            onTap: () {
                              final nextIndex = _days.indexWhere(
                                (candidate) => _sameDate(candidate, itemDay),
                              );
                              if (nextIndex != -1) {
                                setState(() => _dayIndex = nextIndex);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weekdayLabel(itemDay),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${itemDay.day}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_showWeekFadeLeft)
                        const Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: _WeekEdgeFade(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      if (_showWeekFadeRight)
                        const Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: _WeekEdgeFade(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatEventDay(day),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${events.length} event${events.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                    child: SizedBox(
                      height: 24 * _hourRowHeight,
                      child: Stack(
                        children: [
                          for (int hour = 0; hour < 24; hour++)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: hour * _hourRowHeight,
                              height: _hourRowHeight,
                              child: _buildHourRow(hour),
                            ),
                          for (final event in events) _buildTimelineEventCard(event),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(int hour) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Text(
              _formatHourLabel(hour),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEventCard(_PlannerEvent event) {
    final startMinutes = event.start.hour * 60 + event.start.minute;
    final top = (startMinutes / 60) * _hourRowHeight;
    final height = (event.duration.inMinutes / 60.0) * _hourRowHeight;
    final cardHeight = height < 24 ? 24.0 : height;
    final compact = cardHeight < 64;
    final contentPadding = compact ? 5.0 : 10.0;
    final titleFontSize = compact ? 12.0 : 14.0;
    final showTime = cardHeight >= 64;
    final showLocation = cardHeight >= 92;
    final endTime = TimeOfDay.fromDateTime(event.start.add(event.duration));

    return Positioned(
      left: 58,
      right: 0,
      top: top,
      height: cardHeight,
      child: GestureDetector(
        onTap: () => _showEventSheet(event),
        child: Container(
          padding: EdgeInsets.all(contentPadding),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: event.color.withValues(alpha: 0.75)),
          ),
          child: compact
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: event.color,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: event.color,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    if (showTime) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${_formatTime(TimeOfDay.fromDateTime(event.start))} - ${_formatTime(endTime)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                    if (showLocation && event.recurrenceLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.recurrenceLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: event.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (showLocation) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAlarmApp() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Alarm',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _openAlarmEditor(),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _alarms.isEmpty
                ? const Center(
                    child: Text(
                      'No alarms',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) =>
                        _buildAlarmCard(_alarms[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('done'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(_PlannerAlarm alarm) {
    return GestureDetector(
      onTap: () => _openAlarmEditor(existing: alarm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alarm.enabled
                ? NunuColors.primaryMain.withValues(alpha: 0.45)
                : Colors.grey.shade700,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatTime(alarm.time),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w300,
                      color: alarm.enabled ? Colors.white : Colors.white38,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                Switch(
                  value: alarm.enabled,
                  onChanged: (value) {
                    setState(() {
                      final index = _alarms.indexWhere((a) => a.id == alarm.id);
                      if (index != -1) {
                        _alarms[index] = alarm.copy(enabled: value);
                      }
                    });
                  },
                  activeColor: NunuColors.primaryMain,
                  activeTrackColor:
                      NunuColors.primaryMain.withValues(alpha: 0.45),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alarm.label,
              style: TextStyle(
                color: alarm.enabled ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alarm.oneTimeDate != null
                  ? _formatEventDay(alarm.oneTimeDate!)
                  : _formatRepeatDays(alarm.repeatDays),
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alarm.snoozeMinutes == 0
                  ? 'snooze off'
                  : 'snooze ${alarm.snoozeMinutes} minutes',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(DateTime day) => _dayShort[day.weekday - 1];

  String _formatEventDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${_weekdayLabel(date)}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatHourLabel(int hour) {
    final normalized = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour < 12 ? 'AM' : 'PM';
    return '$normalized $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatRepeatDays(Set<int> days) {
    if (_sameDays(days, {0, 1, 2, 3, 4})) return 'Mon, Tue, Wed, Thu, Fri';
    if (_sameDays(days, {5, 6})) return 'Sat, Sun';
    final ordered = days.toList()..sort();
    return ordered.map((day) => _dayShort[day]).join(', ');
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameDays(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class _AppTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AppTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? NunuColors.primaryMain : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekEdgeFade extends StatelessWidget {
  final Alignment begin;
  final Alignment end;

  const _WeekEdgeFade({
    required this.begin,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: const [
            Color(0xFFF4F6FA),
            Color(0x00F4F6FA),
          ],
        ),
      ),
    );
  }
}

class _PlannerScenario {
  final List<_PlannerEvent> events;
  final List<_PlannerAlarm> initialAlarms;
  final List<_PlannerAlarm> expectedAlarms;
  final List<DateTime> visibleWeek;

  const _PlannerScenario({
    required this.events,
    required this.initialAlarms,
    required this.expectedAlarms,
    required this.visibleWeek,
  });
}

class _PlannerEvent {
  final String id;
  final String title;
  final String location;
  final String note;
  final String? recurrenceLabel;
  final DateTime start;
  final Duration duration;
  final Color color;

  const _PlannerEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.note,
    this.recurrenceLabel,
    required this.start,
    required this.duration,
    required this.color,
  });
}

class _PlannerAlarm {
  final String id;
  final String label;
  final TimeOfDay time;
  final Set<int> repeatDays;
  final DateTime? oneTimeDate;
  final bool enabled;
  final int snoozeMinutes;

  const _PlannerAlarm({
    required this.id,
    required this.label,
    required this.time,
    required this.repeatDays,
    this.oneTimeDate,
    required this.enabled,
    required this.snoozeMinutes,
  });

  _PlannerAlarm copy({
    String? id,
    String? label,
    TimeOfDay? time,
    Set<int>? repeatDays,
    DateTime? oneTimeDate,
    bool? enabled,
    int? snoozeMinutes,
  }) {
    return _PlannerAlarm(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      repeatDays: {...(repeatDays ?? this.repeatDays)},
      oneTimeDate: oneTimeDate ?? this.oneTimeDate,
      enabled: enabled ?? this.enabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}

class _Evaluation {
  final double score;
  final Map<String, dynamic> metrics;

  const _Evaluation({
    required this.score,
    required this.metrics,
  });
}
