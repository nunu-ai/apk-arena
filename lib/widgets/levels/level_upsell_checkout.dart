import 'dart:async';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/food/food_models.dart';
import '../level_components/food/food_cart.dart';
import '../level_components/food/food_shop_detail.dart';
import '../level_components/food/food_shop_overview.dart';

class LevelUpsellCheckout extends LevelWidget {
  const LevelUpsellCheckout({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelUpsellCheckout> createState() => _LevelUpsellCheckoutState();
}

class _LevelUpsellCheckoutState extends State<LevelUpsellCheckout> {
  late final FoodShop _shop;
  FoodShop? _selected;
  final List<CartItem> _cart = [];

  bool _showPromoPopup = false; // first popup after initial delay
  bool _showAddUpsell = false; // shown after add-to-cart
  bool _showCheckoutUpsell = false; // intercept on checkout
  int _addUpsellCycle = 0; // rotate suggested items
  int _checkoutUpsellStage = 0; // escalate nags on checkout
  bool _sneakyVipAdded = false; // silently add VIP once
  int _bannerSeconds = 36000; // ~10 hours left
  int _popupCountdown = 5; // initial delay before first popup
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _shop = _buildShop();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_bannerSeconds > 0) _bannerSeconds--;
        _popupCountdown = (_popupCountdown - 1).clamp(0, 99999);
        if (_popupCountdown == 0) {
          if (!_isTargetOrder() && !_anyPopupOpen) {
            _showPromoPopup = true;
          }
          _popupCountdown = 30; // reappear cadence
        }
      });
    });
  }

  FoodShop _buildShop() {
    const plain = FoodItem(
      id: 'plain_bagel',
      name: 'plain bagel',
      type: 'bagel',
      price: 2.00,
      emoji: '🥯',
    );
    const everything = FoodItem(
      id: 'everything_bagel',
      name: 'everything bagel',
      type: 'bagel',
      price: 2.50,
      emoji: '🥯',
    );
    const coffee = FoodItem(
      id: 'coffee',
      name: 'coffee',
      type: 'drink',
      price: 3.00,
      emoji: '☕',
    );
    const vip = FoodItem(
      id: 'vip_subscription',
      name: 'vip monthly',
      type: 'subscription',
      price: 14.99,
      emoji: '💳',
    );
    const mug = FoodItem(
      id: 'free_mug',
      name: 'limited mug',
      type: 'promo',
      price: 0.00,
      emoji: '🫖',
    );
    return const FoodShop(
      id: 'bagel_hut',
      name: 'bagel hut',
      emoji: '🥯',
      items: [plain, everything, coffee, vip, mug],
    );
  }

  void _addToCart(CartItem item) {
    setState(() {
      _cart.add(item);
      // sneaky: silently add VIP once (unless already adding VIP)
      if (!_sneakyVipAdded && item.item.id != 'vip_subscription') {
        final vip = _shop.items.firstWhere((e) => e.id == 'vip_subscription');
        _cart.add(CartItem(item: vip));
        _sneakyVipAdded = true;
      }
      // show add-to-cart upsell modal (if none open)
      if (!_anyPopupOpen) {
        _showAddUpsell = true;
        _addUpsellCycle++;
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  bool _isTargetOrder() {
    if (_cart.length != 1) return false;
    final c = _cart.first;
    return c.item.id == 'plain_bagel' &&
        c.quantity == 1 &&
        c.removedToppingIds.isEmpty;
  }

  void _attemptOrder() {
    final success = _isTargetOrder();
    widget.onComplete(success);
  }

  void _handlePlaceOrderPressed() {
    // intercept checkout with escalating upsells before allowing order
    if (!_anyPopupOpen && _checkoutUpsellStage < 2) {
      setState(() {
        _showCheckoutUpsell = true;
      });
      return;
    }
    _attemptOrder();
  }

  void _addBundleToCart() {
    // banner: add VIP membership to cart without checking out
    final vip = _shop.items.firstWhere((e) => e.id == 'vip_subscription');
    setState(() {
      _cart.add(CartItem(item: vip));
      _showPromoPopup = false;
      _popupCountdown = 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Nunu-themed wrapper; inner area is light shop UI
        Container(
          color: NunuColors.backgroundDefault,
          child: Column(
            children: [
              // Light-themed shop UI inside
              Expanded(
                child: Material(
                  color: const Color(0xFFE6EBF0),
                  child: Column(
                    children: [
                      // Massive limited-time ad banner at the top
                      _topAdBanner(),
                      Expanded(
                        child: _selected == null
                            ? FoodShopOverview(
                                shops: [_shop],
                                onSelect: (s) => setState(() => _selected = s),
                              )
                            : FoodShopDetail(
                                shop: _selected!,
                                onAddToCart: _addToCart,
                                onBack: () => setState(() => _selected = null),
                              ),
                      ),
                      FoodCartPanel(
                        items: _cart,
                        onPlaceOrder: _handlePlaceOrderPressed,
                        onClear: _cart.isNotEmpty ? _clearCart : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_showPromoPopup) _promoPopup(),
        if (_showAddUpsell) _addUpsellPopup(),
        if (_showCheckoutUpsell) _checkoutUpsellPopup(),
      ],
    );
  }

  bool get _anyPopupOpen =>
      _showPromoPopup || _showAddUpsell || _showCheckoutUpsell;

  Widget _topAdBanner() {
    const gradStart = Color(0xFFFFE08A);
    const gradEnd = Color(0xFFFF6B6B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bannerLabel(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'vip membership — unlock perks instantly',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _addBundleToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('get now'),
          ),
        ],
      ),
    );
  }

  String _bannerLabel() {
    final s = _bannerSeconds;
    final days = s ~/ 86400;
    final hours = (s % 86400) ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    if (days >= 1) {
      return 'limited time — ${days}d ${hours}h left';
    }
    return 'limited time — ${hours}h ${minutes.toString().padLeft(2, '0')}m left';
  }

  Widget _promoPopup() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final cardW = (w * 0.92).clamp(0.0, 560.0);
          final cardH = (h * 0.68).clamp(300.0, 640.0);
          return Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with tiny close X
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.black87,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'buy 2 bagels, get 1 mug free',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() {
                              _showPromoPopup = false;
                              _popupCountdown = 30;
                            }),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black54,
                              size: 14,
                            ), // tiny X
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big hero area
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFF5E6),
                                      Color(0xFFFFE0E0),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        '🥯🥯',
                                        style: TextStyle(fontSize: 42),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '→ 🫖',
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'today only: 2-for-mug',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'add two bagels and claim your free mug.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final mug = _shop.items.firstWhere(
                                    (e) => e.id == 'free_mug',
                                  );
                                  final plain = _shop.items.firstWhere(
                                    (e) => e.id == 'plain_bagel',
                                  );
                                  setState(() {
                                    _cart.add(
                                      CartItem(item: plain, quantity: 2),
                                    );
                                    _cart.add(CartItem(item: mug));
                                    _showPromoPopup = false;
                                    _popupCountdown = 30;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('get now'),
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
        },
      ),
    );
  }

  Widget _addUpsellPopup() {
    // Rotates between suggesting coffee and free mug claim
    final coffee = _shop.items.firstWhere((e) => e.id == 'coffee');
    final mug = _shop.items.firstWhere((e) => e.id == 'free_mug');
    final suggestCoffee = _addUpsellCycle % 2 == 1; // alternate
    final title = suggestCoffee
        ? 'make it a combo'
        : 'limited mug — almost gone';
    final subtitle = suggestCoffee
        ? 'add coffee for \$${coffee.price.toStringAsFixed(2)} and save time later.'
        : 'add your free mug now so we don\'t forget.';
    final emoji = suggestCoffee ? '☕' : '🫖';
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _showAddUpsell = false),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cart.add(
                              CartItem(item: suggestCoffee ? coffee : mug),
                            );
                            _showAddUpsell = false;
                          });
                        },
                        child: Text(suggestCoffee ? 'add coffee' : 'add mug'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _showAddUpsell = false),
                      child: const Text('no thanks'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutUpsellPopup() {
    // Two-stage nag: coffee then VIP
    final coffee = _shop.items.firstWhere((e) => e.id == 'coffee');
    final vip = _shop.items.firstWhere((e) => e.id == 'vip_subscription');
    final isStageOne = _checkoutUpsellStage == 0;
    final title = isStageOne
        ? 'wait — you\'ll want coffee'
        : 'almost done — unlock vip perks';
    final subtitle = isStageOne
        ? 'bagels + coffee = happiness. add coffee for just \$${coffee.price.toStringAsFixed(2)}.'
        : 'skip the line, member discounts, priority toast level. only \$${vip.price.toStringAsFixed(2)}.';
    final addLabel = isStageOne ? 'add coffee' : 'add vip';
    final emoji = isStageOne ? '☕' : '💳';
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() {
                        _showCheckoutUpsell = false;
                        _checkoutUpsellStage++;
                      }),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cart.add(
                              CartItem(item: isStageOne ? coffee : vip),
                            );
                            _showCheckoutUpsell = false;
                            _checkoutUpsellStage++;
                          });
                        },
                        child: Text(addLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _showCheckoutUpsell = false;
                        _checkoutUpsellStage++;
                      }),
                      child: const Text('no thanks'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
