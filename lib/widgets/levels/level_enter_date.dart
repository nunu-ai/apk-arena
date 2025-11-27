import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEnterDate extends LevelWidget {
  const LevelEnterDate({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEnterDate> createState() => _LevelEnterDateState();
}

class _LevelEnterDateState extends State<LevelEnterDate> {
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();

  @override
  void dispose() {
    _year.dispose();
    _month.dispose();
    _day.dispose();
    super.dispose();
  }

  void _submit() {
    final now = DateTime.now();
    final y = int.tryParse(_year.text.trim());
    final m = int.tryParse(_month.text.trim());
    final d = int.tryParse(_day.text.trim());
    if (y == now.year && m == now.month && d == now.day) {
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: NunuColors.backgroundPaper,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: _numField(label: 'year', controller: _year, maxLen: 4, hint: 'yyyy')),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(label: 'month', controller: _month, maxLen: 2, hint: 'mm')),
                          const SizedBox(width: 12),
                          Expanded(child: _numField(label: 'day', controller: _day, maxLen: 2, hint: 'dd')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField({required String label, required TextEditingController controller, required int maxLen, required String hint}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
