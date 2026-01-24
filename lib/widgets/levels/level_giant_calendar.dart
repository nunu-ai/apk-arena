import 'package:flutter/material.dart';
import '../level_widget.dart';

// =============================================================================
// CALENDAR EVENT MODEL
// =============================================================================

class _CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final Duration duration;
  final String? attendee;
  final Color color;

  const _CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    this.duration = const Duration(hours: 1),
    this.attendee,
    required this.color,
  });

  _CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    Duration? duration,
    String? attendee,
    Color? color,
    bool clearAttendee = false,
  }) {
    return _CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      attendee: clearAttendee ? null : (attendee ?? this.attendee),
      color: color ?? this.color,
    );
  }
}

// =============================================================================
// MAIN LEVEL WIDGET
// =============================================================================

class LevelGiantCalendar extends LevelWidget {
  const LevelGiantCalendar({super.key, required super.onComplete});

  @override
  State<LevelGiantCalendar> createState() => _LevelGiantCalendarState();
}

class _LevelGiantCalendarState extends State<LevelGiantCalendar> {
  // ---------------------------------------------------------------------------
  // CONSTANTS
  // ---------------------------------------------------------------------------
  static const double _timeGutterWidth = 56.0;
  static const double _dayColumnWidth = 160.0;
  static const double _hourHeight = 100.0;
  static const double _headerHeight = 56.0;
  static const double _dayHeaderHeight = 64.0;

  static const Color _accentBlue = Color(0xFF4285F4);
  static const Color _gridLine = Color(0xFFE0E0E0);
  static const Color _gridLineDark = Color(0xFFBDBDBD);

  // Event colors
  static const _colors = (
    blue: Color(0xFF4285F4),
    green: Color(0xFF34A853),
    red: Color(0xFFEA4335),
    purple: Color(0xFF9C27B0),
    orange: Color(0xFFFF9800),
    teal: Color(0xFF00ACC1),
  );

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  int _currentMonth = 1;
  int _currentYear = 2026;
  late List<_CalendarEvent> _events;
  final _transformController = TransformationController();
  double _scrollX = 0;
  double _scrollY = 0;

  // Target for completion check - Dr. Spaceman appointment
  static const _drSpacemanId = 'dr-spaceman-appt';
  // Original time: 3:30 PM (15:30), Target time: 2:30 PM (14:30) - 1 hour earlier
  static final _targetMovedTime = DateTime(2026, 2, 14, 14, 30);

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _events = _createEvents();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  Size _viewportSize = Size.zero;

  void _onTransformChanged() {
    final matrix = _transformController.value;
    final tx = -matrix.getTranslation().x;
    final ty = -matrix.getTranslation().y;
    
    // Clamp scroll position to valid bounds
    final maxScrollX = (_timeGutterWidth + _gridWidth - _viewportSize.width).clamp(0.0, double.infinity);
    final maxScrollY = (_dayHeaderHeight + _gridHeight - _viewportSize.height).clamp(0.0, double.infinity);
    
    final clampedX = tx.clamp(0.0, maxScrollX);
    final clampedY = ty.clamp(0.0, maxScrollY);
    
    // If clamping changed the values, update the transform controller
    if ((tx - clampedX).abs() > 0.5 || (ty - clampedY).abs() > 0.5) {
      final newMatrix = Matrix4.identity()..translate(-clampedX, -clampedY);
      _transformController.value = newMatrix;
    }
    
    setState(() {
      _scrollX = clampedX;
      _scrollY = clampedY;
    });
  }

  // ---------------------------------------------------------------------------
  // COMPUTED PROPERTIES
  // ---------------------------------------------------------------------------
  int get _daysInCurrentMonth => DateTime(_currentYear, _currentMonth + 1, 0).day;
  double get _gridWidth => _daysInCurrentMonth * _dayColumnWidth;
  double get _gridHeight => 24 * _hourHeight;

  String get _monthName {
    const names = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return names[_currentMonth - 1];
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  void _previousMonth() {
    setState(() {
      _currentMonth = _currentMonth == 1 ? 12 : _currentMonth - 1;
      _currentYear = _currentMonth == 12 ? _currentYear - 1 : _currentYear;
      _transformController.value = Matrix4.identity();
      _scrollX = 0;
      _scrollY = 0;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = _currentMonth == 12 ? 1 : _currentMonth + 1;
      _currentYear = _currentMonth == 1 ? _currentYear + 1 : _currentYear;
      _transformController.value = Matrix4.identity();
      _scrollX = 0;
      _scrollY = 0;
    });
  }

  void _deleteEvent(String id) {
    setState(() => _events.removeWhere((e) => e.id == id));
    _checkCompletion();
  }

  void _addEvent(_CalendarEvent event) {
    setState(() => _events.add(event));
    _checkCompletion();
  }

  void _updateEvent(String id, _CalendarEvent updatedEvent) {
    setState(() {
      final index = _events.indexWhere((e) => e.id == id);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
    });
    _checkCompletion();
  }

  void _checkCompletion() {
    // Check if Dr. Spaceman appointment was moved to 2:30 PM (1 hour earlier from 3:30 PM)
    final drSpacemanEvent = _events.firstWhere(
      (e) => e.id == _drSpacemanId,
      orElse: () => _CalendarEvent(id: '', title: '', dateTime: DateTime(2000), color: Colors.transparent),
    );
    
    if (drSpacemanEvent.id.isEmpty) return; // Event was deleted, not moved
    
    // Check if the event time is now 2:30 PM on Feb 14 (within 5 min tolerance)
    final movedCorrectly = drSpacemanEvent.dateTime.year == _targetMovedTime.year &&
        drSpacemanEvent.dateTime.month == _targetMovedTime.month &&
        drSpacemanEvent.dateTime.day == _targetMovedTime.day &&
        drSpacemanEvent.dateTime.difference(_targetMovedTime).inMinutes.abs() <= 5;
    
    if (movedCorrectly) widget.onComplete(true);
  }

  List<_CalendarEvent> _getEventsForDay(DateTime day) {
    return _events
        .where((e) => e.dateTime.year == day.year &&
                      e.dateTime.month == day.month &&
                      e.dateTime.day == day.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentBlue,
        onPressed: () => _showCreateDialog(
          DateTime(_currentYear, _currentMonth, 1),
          const TimeOfDay(hour: 9, minute: 0),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildMonthHeader(),
          Expanded(child: _buildCalendarBody()),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _accentBlue,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: _previousMonth,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$_monthName $_currentYear',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Capture viewport size for scroll clamping
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            // Main scrollable grid (with time gutter space for clipping)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: EdgeInsets.zero,
                minScale: 1.0,
                maxScale: 1.0,
                constrained: false,
                panEnabled: true,
                scaleEnabled: false,
                child: SizedBox(
                  width: _timeGutterWidth + _gridWidth,
                  height: _dayHeaderHeight + _gridHeight,
                  child: Stack(
                    children: [
                      // Grid background with lines
                      Positioned(
                        left: _timeGutterWidth,
                        top: _dayHeaderHeight,
                        width: _gridWidth,
                        height: _gridHeight,
                        child: _buildGrid(),
                      ),
                      // Events
                      Positioned(
                        left: _timeGutterWidth,
                        top: _dayHeaderHeight,
                        width: _gridWidth,
                        height: _gridHeight,
                        child: _buildEvents(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky day headers (top)
            Positioned(
              left: _timeGutterWidth - _scrollX,
              top: 0,
              child: _buildDayHeaders(),
            ),

            // Sticky time gutter (left)
            Positioned(
              left: 0,
              top: _dayHeaderHeight - _scrollY,
              child: _buildTimeGutter(),
            ),

            // Corner piece (intersection)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: _timeGutterWidth,
                height: _dayHeaderHeight,
                color: Colors.grey[100],
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: _gridLineDark),
                      bottom: BorderSide(color: _gridLineDark),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      height: _dayHeaderHeight,
      width: _gridWidth,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: _gridLineDark)),
      ),
      child: Row(
        children: List.generate(_daysInCurrentMonth, (i) {
          final day = i + 1;
          final date = DateTime(_currentYear, _currentMonth, day);
          final weekday = weekdays[date.weekday % 7];
          final isTarget = _currentMonth == 1 && _currentYear == 2026 && day == 10;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showCreateDialog(date, const TimeOfDay(hour: 9, minute: 0)),
            child: Container(
              width: _dayColumnWidth,
              decoration: BoxDecoration(
                color: isTarget ? _accentBlue.withValues(alpha: 0.1) : null,
                border: Border(left: BorderSide(color: _gridLine)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(weekday, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  const SizedBox(height: 2),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isTarget ? _accentBlue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isTarget ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeGutter() {
    return Container(
      width: _timeGutterWidth,
      height: _gridHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: _gridLineDark)),
      ),
      child: Column(
        children: List.generate(24, (hour) {
          final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          final period = hour >= 12 ? 'PM' : 'AM';
          return Container(
            height: _hourHeight,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Text(
              '$h $period',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      size: Size(_gridWidth, _gridHeight),
      painter: _GridPainter(
        days: _daysInCurrentMonth,
        dayWidth: _dayColumnWidth,
        hourHeight: _hourHeight,
        lineColor: _gridLine,
      ),
    );
  }

  Widget _buildEvents() {
    return Stack(
      children: [
        // Tap targets for each hour cell
        for (int d = 0; d < _daysInCurrentMonth; d++)
          for (int h = 0; h < 24; h++)
            Positioned(
              left: d * _dayColumnWidth,
              top: h * _hourHeight,
              width: _dayColumnWidth,
              height: _hourHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _showCreateDialog(
                  DateTime(_currentYear, _currentMonth, d + 1),
                  TimeOfDay(hour: h, minute: 0),
                ),
              ),
            ),
        // Event blocks
        for (int d = 0; d < _daysInCurrentMonth; d++)
          ..._getEventsForDay(DateTime(_currentYear, _currentMonth, d + 1))
              .map((e) => _buildEventBlock(e, d)),
      ],
    );
  }

  Widget _buildEventBlock(_CalendarEvent event, int dayIndex) {
    final startHour = event.dateTime.hour + event.dateTime.minute / 60.0;
    final durationHours = event.duration.inMinutes / 60.0;
    final top = startHour * _hourHeight;
    final height = (durationHours * _hourHeight).clamp(20.0, double.infinity);

    return Positioned(
      left: dayIndex * _dayColumnWidth + 2,
      top: top,
      width: _dayColumnWidth - 4,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showEventDialog(event),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: height < 30 ? 2 : 4),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: TextStyle(color: Colors.white, fontSize: height < 30 ? 9 : 11, fontWeight: FontWeight.w600),
                  maxLines: height > 40 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 48 && event.attendee != null)
                  Text(
                    event.attendee!,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS
  // ---------------------------------------------------------------------------
  void _showEventDialog(_CalendarEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: event.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Expanded(child: Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow(Icons.access_time, _formatDateTime(event.dateTime)),
            const SizedBox(height: 6),
            _dialogRow(Icons.timelapse, _formatDuration(event.duration)),
            if (event.attendee != null) ...[const SizedBox(height: 6), _dialogRow(Icons.person, event.attendee!)],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('close', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditEventDialog(event);
            },
            child: Text('edit', style: TextStyle(color: event.color)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(event);
            },
            child: const Text('delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(_CalendarEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('delete event?', style: TextStyle(color: Colors.black87)),
        content: Text('Delete "${event.title}"?', style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEvent(event.id);
            },
            child: const Text('delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(_CalendarEvent event) {
    final titleCtrl = TextEditingController(text: event.title);
    final attendeeCtrl = TextEditingController(text: event.attendee ?? '');
    var selDate = event.dateTime;
    var selTime = TimeOfDay(hour: event.dateTime.hour, minute: event.dateTime.minute);
    var selDuration = event.duration;
    var selColor = event.color;

    final durationOptions = [
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(hours: 1),
      const Duration(hours: 1, minutes: 30),
      const Duration(hours: 2),
      const Duration(hours: 3),
      const Duration(hours: 4),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('edit event', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'title',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentBlue, width: 2)),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attendeeCtrl,
                  decoration: InputDecoration(
                    labelText: 'attendee',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentBlue, width: 2)),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _pickerRow(Icons.calendar_today, _formatDate(selDate), () async {
                  final d = await showDatePicker(context: ctx, initialDate: selDate, firstDate: DateTime(2026), lastDate: DateTime(2027));
                  if (d != null) setDlg(() => selDate = DateTime(d.year, d.month, d.day, selTime.hour, selTime.minute));
                }),
                const SizedBox(height: 12),
                _pickerRow(Icons.access_time, selTime.format(ctx), () async {
                  final t = await showTimePicker(context: ctx, initialTime: selTime);
                  if (t != null) setDlg(() => selTime = t);
                }),
                const SizedBox(height: 12),
                // Duration dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<Duration>(
                    value: durationOptions.contains(selDuration) ? selDuration : durationOptions[3],
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black87),
                    items: durationOptions.map((d) => DropdownMenuItem(
                      value: d,
                      child: Row(
                        children: [
                          Icon(Icons.timelapse, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(_formatDuration(d), style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (d) { if (d != null) setDlg(() => selDuration = d); },
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [_colors.blue, _colors.green, _colors.red, _colors.purple, _colors.orange, _colors.teal]
                      .map((c) => GestureDetector(
                            onTap: () => setDlg(() => selColor = c),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: c == selColor ? Border.all(color: Colors.black, width: 2) : null,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                _updateEvent(event.id, event.copyWith(
                  title: titleCtrl.text.trim(),
                  dateTime: DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute),
                  duration: selDuration,
                  attendee: attendeeCtrl.text.trim().isEmpty ? null : attendeeCtrl.text.trim(),
                  clearAttendee: attendeeCtrl.text.trim().isEmpty,
                  color: selColor,
                ));
                Navigator.pop(ctx);
              },
              child: Text('save', style: TextStyle(color: selColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(DateTime date, TimeOfDay time) {
    final titleCtrl = TextEditingController();
    final attendeeCtrl = TextEditingController();
    var selDate = date;
    var selTime = time;
    var selColor = _colors.blue;
    var selDuration = const Duration(hours: 1);

    final durationOptions = [
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(hours: 1),
      const Duration(hours: 1, minutes: 30),
      const Duration(hours: 2),
      const Duration(hours: 3),
      const Duration(hours: 4),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('new event', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'title',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentBlue, width: 2)),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attendeeCtrl,
                  decoration: InputDecoration(
                    labelText: 'attendee',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentBlue, width: 2)),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _pickerRow(Icons.calendar_today, _formatDate(selDate), () async {
                  final d = await showDatePicker(context: ctx, initialDate: selDate, firstDate: DateTime(2026), lastDate: DateTime(2027));
                  if (d != null) setDlg(() => selDate = d);
                }),
                const SizedBox(height: 12),
                _pickerRow(Icons.access_time, selTime.format(ctx), () async {
                  final t = await showTimePicker(context: ctx, initialTime: selTime);
                  if (t != null) setDlg(() => selTime = t);
                }),
                const SizedBox(height: 12),
                // Duration dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<Duration>(
                    value: selDuration,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black87),
                    items: durationOptions.map((d) => DropdownMenuItem(
                      value: d,
                      child: Row(
                        children: [
                          Icon(Icons.timelapse, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(_formatDuration(d), style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (d) { if (d != null) setDlg(() => selDuration = d); },
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [_colors.blue, _colors.green, _colors.red, _colors.purple, _colors.orange, _colors.teal]
                      .map((c) => GestureDetector(
                            onTap: () => setDlg(() => selColor = c),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: c == selColor ? Border.all(color: Colors.black, width: 2) : null,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                _addEvent(_CalendarEvent(
                  id: 'user-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  dateTime: DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute),
                  duration: selDuration,
                  attendee: attendeeCtrl.text.trim().isEmpty ? null : attendeeCtrl.text.trim(),
                  color: selColor,
                ));
                Navigator.pop(ctx);
              },
              child: Text('save', style: TextStyle(color: selColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13))),
      ],
    );
  }

  Widget _pickerRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Colors.black87))],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORMATTING
  // ---------------------------------------------------------------------------
  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }

  String _formatDateTime(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(d)} at $h:${d.minute.toString().padLeft(2, '0')} $p';
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours}h' : '${d.inHours}h ${m}m';
    }
    return '${d.inMinutes}m';
  }

  // ---------------------------------------------------------------------------
  // EVENT DATA
  // ---------------------------------------------------------------------------
  List<_CalendarEvent> _createEvents() => [
    // TARGET EVENT - Dr. Spaceman appointment at 3:30 PM, needs to be moved to 2:30 PM
    _CalendarEvent(id: _drSpacemanId, title: 'Doctor Appointment', dateTime: DateTime(2026, 2, 14, 15, 30), duration: const Duration(hours: 1), attendee: 'Dr. Spaceman', color: _colors.red),
    // JANUARY
    _CalendarEvent(id: 'j1', title: 'New Year Planning', dateTime: DateTime(2026, 1, 2, 9, 0), duration: const Duration(hours: 2), attendee: 'All Staff', color: _colors.blue),
    _CalendarEvent(id: 'j2', title: 'Budget Review', dateTime: DateTime(2026, 1, 2, 14, 0), duration: const Duration(hours: 1), attendee: 'Finance', color: _colors.green),
    _CalendarEvent(id: 'j3', title: 'IT Security Training', dateTime: DateTime(2026, 1, 3, 10, 0), duration: const Duration(hours: 3), attendee: 'IT Dept', color: _colors.purple),
    _CalendarEvent(id: 'j4', title: 'Client Lunch', dateTime: DateTime(2026, 1, 3, 12, 30), duration: const Duration(hours: 1, minutes: 30), attendee: 'Initech', color: _colors.orange),
    _CalendarEvent(id: 'j5', title: 'Sprint Planning', dateTime: DateTime(2026, 1, 6, 9, 0), duration: const Duration(hours: 2), attendee: 'Dev Team', color: _colors.blue),
    _CalendarEvent(id: 'j6', title: 'Synergy Workshop', dateTime: DateTime(2026, 1, 6, 14, 0), duration: const Duration(hours: 3), attendee: 'Leadership', color: _colors.purple),
    _CalendarEvent(id: 'j7', title: '1:1 with Lumberg', dateTime: DateTime(2026, 1, 7, 15, 0), duration: const Duration(minutes: 30), attendee: 'Bill Lumberg', color: _colors.blue),
    _CalendarEvent(id: 'j8', title: 'Code Review', dateTime: DateTime(2026, 1, 7, 10, 0), duration: const Duration(hours: 2), attendee: 'Dev Team', color: _colors.teal),
    _CalendarEvent(id: 'j9', title: 'Mandatory Fun', dateTime: DateTime(2026, 1, 8, 14, 0), duration: const Duration(hours: 1), attendee: 'HR', color: _colors.orange),
    _CalendarEvent(id: 'j10', title: 'Product Demo', dateTime: DateTime(2026, 1, 8, 11, 0), duration: const Duration(hours: 1), attendee: 'Sales', color: _colors.blue),
    _CalendarEvent(id: 'j11', title: 'TPS Report Training', dateTime: DateTime(2026, 1, 9, 9, 0), duration: const Duration(hours: 2), attendee: 'All Staff', color: _colors.red),
    _CalendarEvent(id: 'j12', title: 'Architecture Review', dateTime: DateTime(2026, 1, 10, 14, 0), duration: const Duration(hours: 2), attendee: 'Tech Leads', color: _colors.teal),
    _CalendarEvent(id: 'j13', title: 'Cover Sheet Training', dateTime: DateTime(2026, 1, 13, 11, 0), duration: const Duration(hours: 1), attendee: 'Lumberg', color: _colors.blue),
    _CalendarEvent(id: 'j14', title: 'Client Call', dateTime: DateTime(2026, 1, 13, 15, 0), duration: const Duration(hours: 1), attendee: 'Sales', color: _colors.green),
    _CalendarEvent(id: 'j15', title: 'PC Load Letter Fix', dateTime: DateTime(2026, 1, 14, 10, 0), duration: const Duration(minutes: 45), attendee: 'IT', color: _colors.red),
    _CalendarEvent(id: 'j16', title: 'Design Review', dateTime: DateTime(2026, 1, 14, 14, 0), duration: const Duration(hours: 2), attendee: 'UX Team', color: _colors.purple),
    _CalendarEvent(id: 'j17', title: 'Sprint Retro', dateTime: DateTime(2026, 1, 15, 16, 0), duration: const Duration(hours: 1), attendee: 'Dev Team', color: _colors.blue),
    _CalendarEvent(id: 'j18', title: 'Investor Update', dateTime: DateTime(2026, 1, 16, 10, 0), duration: const Duration(hours: 1), attendee: 'Execs', color: _colors.red),
    _CalendarEvent(id: 'j19', title: "Milton's Birthday", dateTime: DateTime(2026, 1, 17, 15, 30), duration: const Duration(hours: 1), color: _colors.orange),
    _CalendarEvent(id: 'j20', title: 'Supply Audit', dateTime: DateTime(2026, 1, 20, 9, 0), duration: const Duration(hours: 2), attendee: 'Milton', color: _colors.green),
    _CalendarEvent(id: 'j21', title: 'Stakeholder Meeting', dateTime: DateTime(2026, 1, 20, 14, 0), duration: const Duration(hours: 2), attendee: 'PMO', color: _colors.blue),
    _CalendarEvent(id: 'j22', title: 'Team Lunch', dateTime: DateTime(2026, 1, 21, 12, 0), duration: const Duration(hours: 1), color: _colors.orange),
    _CalendarEvent(id: 'j23', title: 'Flair Review', dateTime: DateTime(2026, 1, 22, 13, 0), duration: const Duration(hours: 1), attendee: 'Stan', color: _colors.blue),
    _CalendarEvent(id: 'j24', title: 'Security Deploy', dateTime: DateTime(2026, 1, 22, 22, 0), duration: const Duration(hours: 2), attendee: 'DevOps', color: _colors.red),
    _CalendarEvent(id: 'j25', title: 'Jump to Conclusions', dateTime: DateTime(2026, 1, 23, 16, 0), duration: const Duration(minutes: 30), attendee: 'Tom', color: _colors.purple),
    _CalendarEvent(id: 'j26', title: 'All-Hands', dateTime: DateTime(2026, 1, 24, 10, 0), duration: const Duration(hours: 1), attendee: 'Everyone', color: _colors.blue),
    _CalendarEvent(id: 'j27', title: 'Strategy Session', dateTime: DateTime(2026, 1, 27, 9, 0), duration: const Duration(hours: 3), attendee: 'Leadership', color: _colors.purple),
    _CalendarEvent(id: 'j28', title: 'Efficiency Consult', dateTime: DateTime(2026, 1, 28, 10, 0), duration: const Duration(hours: 2), attendee: 'The Bobs', color: _colors.red),
    _CalendarEvent(id: 'j29', title: 'Release Planning', dateTime: DateTime(2026, 1, 29, 14, 0), duration: const Duration(hours: 2), attendee: 'Product', color: _colors.teal),
    _CalendarEvent(id: 'j30', title: 'Interview', dateTime: DateTime(2026, 1, 30, 11, 0), duration: const Duration(hours: 1), attendee: 'HR', color: _colors.green),
    _CalendarEvent(id: 'j31', title: 'Hawaiian Shirt Day', dateTime: DateTime(2026, 1, 31, 8, 0), duration: const Duration(hours: 8), color: _colors.orange),
    // FEBRUARY
    _CalendarEvent(id: 'f1', title: 'Monthly Kickoff', dateTime: DateTime(2026, 2, 2, 9, 0), duration: const Duration(hours: 1), attendee: 'All Staff', color: _colors.blue),
    _CalendarEvent(id: 'f2', title: 'Q1 Planning', dateTime: DateTime(2026, 2, 3, 10, 0), duration: const Duration(hours: 3), attendee: 'Managers', color: _colors.purple),
    _CalendarEvent(id: 'f3', title: 'Vendor Meeting', dateTime: DateTime(2026, 2, 4, 14, 0), duration: const Duration(hours: 1), attendee: 'Procurement', color: _colors.green),
    _CalendarEvent(id: 'f4', title: 'Sprint Demo', dateTime: DateTime(2026, 2, 5, 15, 0), duration: const Duration(hours: 1), attendee: 'Stakeholders', color: _colors.blue),
    _CalendarEvent(id: 'f5', title: 'Team Building', dateTime: DateTime(2026, 2, 6, 13, 0), duration: const Duration(hours: 4), attendee: 'Everyone', color: _colors.orange),
    _CalendarEvent(id: 'f6', title: 'Board Presentation', dateTime: DateTime(2026, 2, 9, 10, 0), duration: const Duration(hours: 2), attendee: 'Execs', color: _colors.red),
    _CalendarEvent(id: 'f7', title: 'Tech Talk Tuesday', dateTime: DateTime(2026, 2, 10, 12, 0), duration: const Duration(hours: 1), attendee: 'Engineering', color: _colors.teal),
    _CalendarEvent(id: 'f8', title: 'Feedback Review', dateTime: DateTime(2026, 2, 11, 14, 0), duration: const Duration(hours: 1), attendee: 'Product', color: _colors.blue),
    _CalendarEvent(id: 'f9', title: 'Infra Review', dateTime: DateTime(2026, 2, 12, 11, 0), duration: const Duration(hours: 2), attendee: 'DevOps', color: _colors.purple),
    _CalendarEvent(id: 'f10', title: 'Pre-Valentine Planning', dateTime: DateTime(2026, 2, 13, 16, 0), duration: const Duration(hours: 1), color: _colors.orange),
    _CalendarEvent(id: 'f11', title: 'Morning Standup', dateTime: DateTime(2026, 2, 14, 9, 0), duration: const Duration(minutes: 15), color: _colors.blue),
    _CalendarEvent(id: 'f12', title: 'Marketing Sync', dateTime: DateTime(2026, 2, 16, 10, 0), duration: const Duration(hours: 1), attendee: 'Marketing', color: _colors.green),
    _CalendarEvent(id: 'f13', title: 'Sales Pipeline', dateTime: DateTime(2026, 2, 17, 14, 0), duration: const Duration(hours: 2), attendee: 'Sales', color: _colors.blue),
    _CalendarEvent(id: 'f14', title: 'Compliance Training', dateTime: DateTime(2026, 2, 18, 9, 0), duration: const Duration(hours: 3), attendee: 'Legal', color: _colors.purple),
    _CalendarEvent(id: 'f15', title: 'Reviews Due', dateTime: DateTime(2026, 2, 19, 17, 0), duration: const Duration(hours: 1), attendee: 'HR', color: _colors.red),
    _CalendarEvent(id: 'f16', title: 'Happy Hour', dateTime: DateTime(2026, 2, 20, 17, 0), duration: const Duration(hours: 2), color: _colors.orange),
    _CalendarEvent(id: 'f17', title: 'Sprint Planning', dateTime: DateTime(2026, 2, 23, 9, 0), duration: const Duration(hours: 2), attendee: 'Dev Team', color: _colors.blue),
    _CalendarEvent(id: 'f18', title: 'Partner Call', dateTime: DateTime(2026, 2, 24, 11, 0), duration: const Duration(hours: 1), attendee: 'BizDev', color: _colors.green),
    _CalendarEvent(id: 'f19', title: 'API Design Review', dateTime: DateTime(2026, 2, 25, 14, 0), duration: const Duration(hours: 2), attendee: 'Tech Leads', color: _colors.teal),
    _CalendarEvent(id: 'f20', title: 'Month-End Close', dateTime: DateTime(2026, 2, 27, 10, 0), duration: const Duration(hours: 4), attendee: 'Finance', color: _colors.red),
    _CalendarEvent(id: 'f21', title: 'EoM Celebration', dateTime: DateTime(2026, 2, 28, 16, 0), duration: const Duration(hours: 2), color: _colors.orange),
    // ADDITIONAL JANUARY EVENTS
    _CalendarEvent(id: 'j32', title: 'Coffee Chat', dateTime: DateTime(2026, 1, 2, 8, 0), duration: const Duration(minutes: 30), attendee: 'Sarah', color: _colors.teal),
    _CalendarEvent(id: 'j33', title: 'Quick Sync', dateTime: DateTime(2026, 1, 5, 9, 30), duration: const Duration(minutes: 15), attendee: 'Mike', color: _colors.blue),
    _CalendarEvent(id: 'j34', title: 'Lunch Break', dateTime: DateTime(2026, 1, 5, 12, 0), duration: const Duration(hours: 1), color: _colors.orange),
    _CalendarEvent(id: 'j35', title: 'Late Night Deploy', dateTime: DateTime(2026, 1, 9, 23, 0), duration: const Duration(hours: 2), attendee: 'DevOps', color: _colors.red),
    _CalendarEvent(id: 'j36', title: 'Early Bird Meeting', dateTime: DateTime(2026, 1, 12, 6, 30), duration: const Duration(minutes: 45), attendee: 'East Coast', color: _colors.purple),
    _CalendarEvent(id: 'j37', title: 'Printer Fix', dateTime: DateTime(2026, 1, 14, 16, 0), duration: const Duration(minutes: 15), attendee: 'IT', color: _colors.teal),
    _CalendarEvent(id: 'j38', title: 'Yoga Class', dateTime: DateTime(2026, 1, 15, 7, 0), duration: const Duration(hours: 1), color: _colors.green),
    _CalendarEvent(id: 'j39', title: 'Networking Event', dateTime: DateTime(2026, 1, 16, 18, 0), duration: const Duration(hours: 3), attendee: 'Industry Peers', color: _colors.purple),
    _CalendarEvent(id: 'j40', title: 'Database Migration', dateTime: DateTime(2026, 1, 18, 2, 0), duration: const Duration(hours: 4), attendee: 'DBA Team', color: _colors.red),
    _CalendarEvent(id: 'j41', title: 'Stand-up Comedy', dateTime: DateTime(2026, 1, 19, 20, 0), duration: const Duration(hours: 2), color: _colors.orange),
    _CalendarEvent(id: 'j42', title: 'Dentist', dateTime: DateTime(2026, 1, 21, 14, 30), duration: const Duration(minutes: 30), attendee: 'Dr. Crentist', color: _colors.teal),
    _CalendarEvent(id: 'j43', title: 'Project Kickoff', dateTime: DateTime(2026, 1, 23, 10, 0), duration: const Duration(hours: 2), attendee: 'New Client', color: _colors.blue),
    _CalendarEvent(id: 'j44', title: 'Brainstorm Session', dateTime: DateTime(2026, 1, 24, 14, 0), duration: const Duration(hours: 1, minutes: 30), attendee: 'Creative Team', color: _colors.purple),
    _CalendarEvent(id: 'j45', title: 'Vendor Demo', dateTime: DateTime(2026, 1, 26, 11, 0), duration: const Duration(hours: 1), attendee: 'Acme Corp', color: _colors.green),
    _CalendarEvent(id: 'j46', title: 'Book Club', dateTime: DateTime(2026, 1, 28, 17, 30), duration: const Duration(hours: 1, minutes: 30), color: _colors.orange),
    _CalendarEvent(id: 'j47', title: 'Quick Call', dateTime: DateTime(2026, 1, 29, 8, 45), duration: const Duration(minutes: 15), attendee: 'Boss', color: _colors.red),
    // ADDITIONAL FEBRUARY EVENTS  
    _CalendarEvent(id: 'f22', title: 'Gym Session', dateTime: DateTime(2026, 2, 2, 6, 0), duration: const Duration(hours: 1), color: _colors.green),
    _CalendarEvent(id: 'f23', title: 'Status Update', dateTime: DateTime(2026, 2, 3, 15, 30), duration: const Duration(minutes: 30), attendee: 'Manager', color: _colors.blue),
    _CalendarEvent(id: 'f24', title: 'Car Service', dateTime: DateTime(2026, 2, 5, 8, 0), duration: const Duration(hours: 2), attendee: 'Mechanic', color: _colors.teal),
    _CalendarEvent(id: 'f25', title: 'Phone Interview', dateTime: DateTime(2026, 2, 6, 10, 0), duration: const Duration(minutes: 45), attendee: 'Candidate', color: _colors.purple),
    _CalendarEvent(id: 'f26', title: 'Dinner Reservation', dateTime: DateTime(2026, 2, 7, 19, 0), duration: const Duration(hours: 2), color: _colors.orange),
    _CalendarEvent(id: 'f27', title: 'Game Night', dateTime: DateTime(2026, 2, 8, 20, 0), duration: const Duration(hours: 3), color: _colors.purple),
    _CalendarEvent(id: 'f28', title: 'Morning Run', dateTime: DateTime(2026, 2, 10, 5, 30), duration: const Duration(minutes: 45), color: _colors.green),
    _CalendarEvent(id: 'f29', title: 'Code Review', dateTime: DateTime(2026, 2, 11, 9, 0), duration: const Duration(hours: 1), attendee: 'Dev Team', color: _colors.teal),
    _CalendarEvent(id: 'f30', title: 'Lunch with Client', dateTime: DateTime(2026, 2, 12, 12, 30), duration: const Duration(hours: 1, minutes: 30), attendee: 'Globex', color: _colors.orange),
    _CalendarEvent(id: 'f31', title: 'Haircut', dateTime: DateTime(2026, 2, 13, 10, 0), duration: const Duration(minutes: 30), color: _colors.blue),
    _CalendarEvent(id: 'f32', title: 'Valentine Dinner', dateTime: DateTime(2026, 2, 14, 19, 0), duration: const Duration(hours: 3), color: _colors.red),
    _CalendarEvent(id: 'f33', title: 'Weekend Planning', dateTime: DateTime(2026, 2, 14, 11, 0), duration: const Duration(minutes: 15), color: _colors.blue),
    _CalendarEvent(id: 'f34', title: 'Movie Night', dateTime: DateTime(2026, 2, 15, 21, 0), duration: const Duration(hours: 2, minutes: 30), color: _colors.purple),
    _CalendarEvent(id: 'f35', title: 'Brunch', dateTime: DateTime(2026, 2, 16, 11, 0), duration: const Duration(hours: 1, minutes: 30), color: _colors.orange),
    _CalendarEvent(id: 'f36', title: 'Oil Change', dateTime: DateTime(2026, 2, 19, 8, 0), duration: const Duration(minutes: 45), color: _colors.teal),
    _CalendarEvent(id: 'f37', title: 'Webinar', dateTime: DateTime(2026, 2, 20, 14, 0), duration: const Duration(hours: 1), attendee: 'Industry Expert', color: _colors.blue),
    _CalendarEvent(id: 'f38', title: 'Night Shift Support', dateTime: DateTime(2026, 2, 21, 22, 0), duration: const Duration(hours: 4), attendee: 'Support Team', color: _colors.red),
    _CalendarEvent(id: 'f39', title: 'Coffee 1:1', dateTime: DateTime(2026, 2, 23, 15, 0), duration: const Duration(minutes: 30), attendee: 'Mentor', color: _colors.green),
    _CalendarEvent(id: 'f40', title: 'Piano Lesson', dateTime: DateTime(2026, 2, 25, 18, 0), duration: const Duration(hours: 1), color: _colors.purple),
  ];
}

// =============================================================================
// GRID PAINTER
// =============================================================================

class _GridPainter extends CustomPainter {
  final int days;
  final double dayWidth;
  final double hourHeight;
  final Color lineColor;

  _GridPainter({required this.days, required this.dayWidth, required this.hourHeight, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    // Horizontal lines (hours)
    for (int h = 0; h <= 24; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines (days)
    for (int d = 0; d <= days; d++) {
      final x = d * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.days != days || old.dayWidth != dayWidth || old.hourHeight != hourHeight;
}
