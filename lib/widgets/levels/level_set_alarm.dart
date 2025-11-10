import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSetAlarm extends LevelWidget {
  const LevelSetAlarm({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSetAlarm> createState() => _LevelSetAlarmState();
}

class _LevelSetAlarmState extends State<LevelSetAlarm> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _selectedDays = {}; // 0 = Monday, 6 = Sunday
  bool _isEnabled = false;
  String _alarmLabel = 'Wake up';

  // Target values
  final TimeOfDay _targetTime = const TimeOfDay(hour: 6, minute: 30);
  final Set<int> _targetDays = {0, 1, 2, 3, 4}; // Monday to Friday

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey.shade900,
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: NunuColors.primaryMain,
              dialBackgroundColor: Colors.grey.shade800,
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? NunuColors.primaryMain
                  : Colors.grey.shade800),
              dayPeriodColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? NunuColors.primaryMain
                  : Colors.grey.shade800),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: NunuColors.primaryMain),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _checkCompletion();
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    _checkCompletion();
  }

  void _toggleAlarm(bool value) {
    setState(() {
      _isEnabled = value;
    });
    _checkCompletion();
  }

  void _checkCompletion() {
    if (_selectedTime.hour == _targetTime.hour &&
        _selectedTime.minute == _targetTime.minute &&
        _selectedDays.containsAll(_targetDays) &&
        _targetDays.containsAll(_selectedDays) &&
        _isEnabled) {
      // Success!
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(true);
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {},
                  ),
                  const Text(
                    'Set Alarm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target instruction
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NunuColors.primaryMain.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NunuColors.primaryMain.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: NunuColors.primaryMain,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Set alarm for:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: NunuColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '6:30 AM, Mon-Fri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: NunuColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Don\'t forget to enable it!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NunuColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Alarm card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isEnabled
                              ? NunuColors.primaryMain.withValues(alpha: 0.5)
                              : Colors.grey.shade700,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time selector
                          GestureDetector(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(_selectedTime),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w300,
                                      color: _isEnabled ? Colors.white : Colors.grey.shade500,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: _isEnabled ? NunuColors.primaryMain : Colors.grey.shade600,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Label
                          Text(
                            _alarmLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _isEnabled ? Colors.white : Colors.grey.shade500,
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 16),

                          // Days selector
                          const Text(
                            'Repeat',
                            style: TextStyle(
                              fontSize: 14,
                              color: NunuColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (index) {
                              final isSelected = _selectedDays.contains(index);
                              return GestureDetector(
                                onTap: () => _toggleDay(index),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? NunuColors.primaryMain
                                        : Colors.grey.shade700,
                                    border: Border.all(
                                      color: isSelected
                                          ? NunuColors.primaryMain
                                          : Colors.grey.shade600,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _dayNames[index],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 16),

                          // Enable toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Alarm enabled',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Switch(
                                value: _isEnabled,
                                onChanged: _toggleAlarm,
                                activeColor: NunuColors.primaryMain,
                                activeTrackColor: NunuColors.primaryMain.withValues(alpha: 0.5),
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional options
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildOption(
                            icon: Icons.notifications_outlined,
                            title: 'Sound',
                            value: 'Default',
                          ),
                          const Divider(color: Colors.grey, height: 24),
                          _buildOption(
                            icon: Icons.vibration,
                            title: 'Vibrate',
                            value: 'On',
                          ),
                          const Divider(color: Colors.grey, height: 24),
                          _buildOption(
                            icon: Icons.snooze,
                            title: 'Snooze',
                            value: '10 minutes',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: NunuColors.textSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: NunuColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right,
          color: NunuColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }
}