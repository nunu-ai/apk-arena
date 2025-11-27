import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelButtonAlchemy extends LevelWidget {
  const LevelButtonAlchemy({Key? key, required super.onComplete}) : super(key: key);

  @override
  State createState() => _LevelButtonAlchemyState();
}

class _LevelButtonAlchemyState extends State<LevelButtonAlchemy> {
  static const int _target = 1337;
  int _value = 1;

  void _apply(void Function() transform) {
    setState(() {
      transform();
    });
    if (_value == _target) {
      widget.onComplete(true);
    }
  }

  void _pressA() {
    _apply(() {
      _value = _value * 2; // hidden rule: double
    });
  }

  void _pressB() {
    _apply(() {
      _value = _value - 5; // hidden rule: decrease by 5
    });
  }

  void _pressC() {
    _apply(() {
      _value = _value + 7; // hidden rule: increase by 7
    });
  }

  void _reset() {
    setState(() {
      _value = 1;
    });
  }

  void _submit() {
    if (_value == _target) {
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
          constraints: const BoxConstraints(maxWidth: 500),
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
                      Text(
                        "target",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: NunuColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _target.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: NunuColors.primaryLight),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: NunuColors.primaryDark.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        "current",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: NunuColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _value.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          IconButton(
                            tooltip: 'reset',
                            onPressed: _reset,
                            icon: const Icon(Icons.restart_alt, color: NunuColors.errorLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _opButton(label: 'a', onPressed: _pressA, color: NunuColors.primaryMain),
                  _opButton(label: 'b', onPressed: _pressB, color: NunuColors.secondaryMain),
                  _opButton(label: 'c', onPressed: _pressC, color: NunuColors.infoMain),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opButton({required String label, required VoidCallback onPressed, required Color color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
