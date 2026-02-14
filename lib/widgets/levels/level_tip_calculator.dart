import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelTipCalculator extends LevelWidget {
  const LevelTipCalculator({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelTipCalculator> createState() => _LevelTipCalculatorState();
}

class _LevelTipCalculatorState extends State<LevelTipCalculator> {
  late List<_ReceiptItem> _receiptItems;
  late int _tipPercent;
  late int _numPeople;
  late double _subtotal;
  late double _correctTip;
  late double _correctPerPerson;

  final _tipController = TextEditingController();
  final _splitController = TextEditingController();
  bool _isComplete = false;
  String? _errorMessage;

  static const List<_MenuItem> _menu = [
    _MenuItem(name: 'margherita pizza', priceRange: [12.50, 18.99]),
    _MenuItem(name: 'caesar salad', priceRange: [8.50, 14.99]),
    _MenuItem(name: 'truffle fries', priceRange: [7.00, 12.50]),
    _MenuItem(name: 'grilled salmon', priceRange: [18.00, 28.99]),
    _MenuItem(name: 'mushroom risotto', priceRange: [14.00, 22.50]),
    _MenuItem(name: 'garlic bread', priceRange: [5.50, 9.99]),
    _MenuItem(name: 'tiramisu', priceRange: [8.00, 13.50]),
    _MenuItem(name: 'sparkling water', priceRange: [3.00, 6.99]),
    _MenuItem(name: 'espresso', priceRange: [3.50, 5.99]),
    _MenuItem(name: 'bruschetta', priceRange: [7.50, 12.99]),
    _MenuItem(name: 'pasta carbonara', priceRange: [13.00, 19.99]),
    _MenuItem(name: 'lemon sorbet', priceRange: [6.00, 9.99]),
  ];

  @override
  void initState() {
    super.initState();
    _generateBill();
  }

  void _generateBill() {
    final rng = Random();

    // pick 3-5 items
    final count = 3 + rng.nextInt(3);
    final shuffled = List<_MenuItem>.from(_menu)..shuffle(rng);
    _receiptItems = shuffled.take(count).map((item) {
      // generate a nice price within range
      final minCents = (item.priceRange[0] * 100).round();
      final maxCents = (item.priceRange[1] * 100).round();
      final priceCents = minCents + rng.nextInt(maxCents - minCents + 1);
      // round to nearest 50 cents for clean math
      final roundedCents = ((priceCents / 50).round() * 50);
      final qty = 1 + (rng.nextDouble() < 0.3 ? 1 : 0); // occasionally 2
      return _ReceiptItem(
        name: item.name,
        price: roundedCents / 100.0,
        quantity: qty,
      );
    }).toList();

    // tip: 15, 18, or 20 percent
    _tipPercent = [15, 18, 20][rng.nextInt(3)];

    // people: 2-4
    _numPeople = 2 + rng.nextInt(3);

    // calculate totals
    _subtotal = _receiptItems.fold(
        0.0, (sum, item) => sum + item.price * item.quantity);
    _correctTip = _subtotal * _tipPercent / 100.0;
    final total = _subtotal + _correctTip;
    _correctPerPerson = total / _numPeople;
  }

  void _handleSubmit() {
    if (_isComplete) return;

    final tipText = _tipController.text.trim();
    final splitText = _splitController.text.trim();

    if (tipText.isEmpty || splitText.isEmpty) {
      setState(() => _errorMessage = 'fill in both fields');
      return;
    }

    final tipValue = double.tryParse(tipText);
    final splitValue = double.tryParse(splitText);

    if (tipValue == null || splitValue == null) {
      setState(() => _errorMessage = 'enter valid numbers');
      return;
    }

    // allow ±0.02 tolerance for rounding
    final tipCorrect = (tipValue - _correctTip).abs() < 0.02;
    final splitCorrect = (splitValue - _correctPerPerson).abs() < 0.02;

    if (tipCorrect && splitCorrect) {
      setState(() {
        _isComplete = true;
        _errorMessage = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(true);
      });
    } else {
      setState(() {
        if (!tipCorrect && !splitCorrect) {
          _errorMessage = 'both values are wrong. check your math!';
        } else if (!tipCorrect) {
          _errorMessage =
              'tip is wrong. ${_tipPercent}% of \$${_subtotal.toStringAsFixed(2)} = ?';
        } else {
          _errorMessage =
              'split is wrong. total / $_numPeople people = ?';
        }
      });
      widget.onComplete(false);
    }
  }

  @override
  void dispose() {
    _tipController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // receipt card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // restaurant header
                        const Text(
                          'RISTORANTE NUNU',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          '~ est. 2024 ~',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _receiptDivider(),
                        const SizedBox(height: 8),

                        // items
                        ..._receiptItems.map((item) => _receiptLine(item)),

                        const SizedBox(height: 8),
                        _receiptDivider(),
                        const SizedBox(height: 8),

                        // subtotal
                        _receiptTotalLine(
                            'subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _receiptTotalLine('tip ($_tipPercent%)', '???'),
                        const SizedBox(height: 4),
                        _receiptTotalLine(
                            'split $_numPeople ways', '??? each'),

                        const SizedBox(height: 8),
                        _receiptDivider(),
                        const SizedBox(height: 8),

                        const Text(
                          'thank you for dining with us!',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // input section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NunuColors.primaryMain.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'calculate the bill',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: NunuColors.primaryLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // tip field
                        _inputField(
                          label: 'tip amount (\$)',
                          controller: _tipController,
                          hint: '0.00',
                        ),
                        const SizedBox(height: 12),

                        // split field
                        _inputField(
                          label: 'amount per person (\$)',
                          controller: _splitController,
                          hint: '0.00',
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  NunuColors.errorMain.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: NunuColors.errorLight, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: NunuColors.errorLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // submit
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isComplete ? null : _handleSubmit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _isComplete
                                  ? NunuColors.successMain
                                  : NunuColors.primaryMain,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isComplete ? 'correct!' : 'submit',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptDivider() {
    return Text(
      '- - - - - - - - - - - - - - - -',
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: 12,
        color: Colors.black.withValues(alpha: 0.2),
        letterSpacing: 2,
      ),
    );
  }

  Widget _receiptLine(_ReceiptItem item) {
    final total = item.price * item.quantity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.quantity > 1
                  ? '${item.name} x${item.quantity}'
                  : item.name,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptTotalLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NunuColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.attach_money,
                color: NunuColors.primaryLight, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ReceiptItem {
  final String name;
  final double price;
  final int quantity;

  const _ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class _MenuItem {
  final String name;
  final List<double> priceRange;

  const _MenuItem({required this.name, required this.priceRange});
}
