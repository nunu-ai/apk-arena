import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../../theme/app_theme.dart';
import '../level_widget.dart';
import '../level_components/chat/chat_history.dart';
import '../level_components/chat/chat_models.dart';
import '../level_components/food/food_cart.dart';
import '../level_components/food/food_models.dart';
import '../level_components/food/food_shop_detail.dart';
import '../level_components/food/food_shop_overview.dart';

class LevelGroupOrder extends LevelWidget {
  const LevelGroupOrder({super.key, required super.onComplete});

  @override
  State createState() => _LevelGroupOrderState();
}

class _LevelGroupOrderState extends State<LevelGroupOrder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Chat data
  late final Map<String, ChatParticipant> _people;
  late final List<ChatMessage> _messages;

  // Shops & cart
  late final List<FoodShop> _shops;
  FoodShop? _selectedShop;
  final List<CartItem> _cart = [];

  static const String _targetShopId = 'bella_napoli';
  static const String _pepperoniId = 'bn_pepperoni';
  static const String _margheritaId = 'bn_margherita';
  static const String _veggieId = 'bn_veggie';
  static const String _bbqId = 'bn_bbq';
  static const String _cokeId = 'bn_coke';
  static const String _mushroomId = 'mushroom';
  static const String _waterId = 'bn_water';
  static const String _garlicBreadId = 'bn_garlic_bread';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _people = const {
      'alex': ChatParticipant('alex', color: Colors.blue),
      'sam': ChatParticipant('sam', color: Colors.purple),
      'jamie': ChatParticipant('jamie', color: Colors.teal),
      'pat': ChatParticipant('pat', color: Colors.orange),
    };

    final now = DateTime.now();
    _messages = [
      ChatMessage(id: 'm1', sender: 'alex', text: 'what do you guys wanna get for dinner?', time: now.subtract(const Duration(minutes: 35))),
      ChatMessage(id: 'm2', sender: 'jamie', text: 'burgers?', time: now.subtract(const Duration(minutes: 34))),
      ChatMessage(id: 'm3', sender: 'sam', text: 'burger barn is good', time: now.subtract(const Duration(minutes: 33))),
      ChatMessage(id: 'm4', sender: 'pat', text: 'nah I want pizza 🍕', time: now.subtract(const Duration(minutes: 32))),
      ChatMessage(id: 'm5', sender: 'alex', text: 'ok pizza it is', time: now.subtract(const Duration(minutes: 31))),
      ChatMessage(id: 'm6', sender: 'jamie', text: 'okeyy :((', time: now.subtract(const Duration(minutes: 30))),
      ChatMessage(id: 'm7', sender: 'sam', text: 'pizza planet or bella napoli?', time: now.subtract(const Duration(minutes: 29))),
      ChatMessage(id: 'm8', sender: 'pat', text: 'planet is cheaper', time: now.subtract(const Duration(minutes: 28))),
      ChatMessage(id: 'm9', sender: 'alex', text: 'yeah but it sucks, bella napoli is so much better', time: now.subtract(const Duration(minutes: 28))),
      ChatMessage(id: 'm10', sender: 'jamie', text: 'margherita 🫡', time: now.subtract(const Duration(minutes: 27))),
      ChatMessage(id: 'm11', sender: 'alex', text: 'ok sure napoli 😊', time: now.subtract(const Duration(minutes: 27))),
      ChatMessage(id: 'm12', sender: 'sam', text: 'pepperoni classic for me', time: now.subtract(const Duration(minutes: 26))),
      ChatMessage(id: 'm13', sender: 'pat', text: 'one bbq chicken', time: now.subtract(const Duration(minutes: 25))),
      ChatMessage(id: 'm14', sender: 'alex', text: 'veggie delight', time: now.subtract(const Duration(minutes: 24))),
      ChatMessage(id: 'm15', sender: 'jamie', text: 'any drinks?', time: now.subtract(const Duration(minutes: 23))),
      ChatMessage(id: 'm16', sender: 'jamie', text: 'coke?', time: now.subtract(const Duration(minutes: 22))),
      ChatMessage(id: 'm17', sender: 'sam', text: 'yea I take one coke', time: now.subtract(const Duration(minutes: 21))),
      ChatMessage(id: 'm18', sender: 'alex', text: 'wait', time: now.subtract(const Duration(minutes: 20))),
      ChatMessage(id: 'm19', sender: 'alex', text: 'should I take hawaiian maybe??', time: now.subtract(const Duration(minutes: 20))),
      ChatMessage(id: 'm20', sender: 'pat', text: 'bruh ☠️', time: now.subtract(const Duration(minutes: 19))),
      ChatMessage(id: 'm21', sender: 'jamie', text: '🤡', time: now.subtract(const Duration(minutes: 19))),
      ChatMessage(id: 'm22', sender: 'pat', text: 'pineapple is disgusting', time: now.subtract(const Duration(minutes: 19))),
      ChatMessage(id: 'm23', sender: 'alex', text: 'lmao', time: now.subtract(const Duration(minutes: 18))),
      ChatMessage(id: 'm24', sender: 'sam', text: 'trueee', time: now.subtract(const Duration(minutes: 17))),
      ChatMessage(id: 'm25', sender: 'alex', text: 'ok then veggie is fine :/', time: now.subtract(const Duration(minutes: 17))),
      ChatMessage(id: 'm26', sender: 'pat', text: 'actually', time: now.subtract(const Duration(minutes: 16))),
      ChatMessage(id: 'm27', sender: 'alex', text: 'no mushrooms tho', time: now.subtract(const Duration(minutes: 16))),
      ChatMessage(id: 'm28', sender: 'jamie', text: 'any garlic bread enjoyers? 😏', time: now.subtract(const Duration(minutes: 15))),
      ChatMessage(id: 'm29', sender: 'pat', text: 'ill take pepperoni instead', time: now.subtract(const Duration(minutes: 14))),
      ChatMessage(id: 'm30', sender: 'alex', text: 'oh yeahh garlic bread', time: now.subtract(const Duration(minutes: 13))),
      ChatMessage(id: 'm31', sender: 'sam', text: 'which pepperoni', time: now.subtract(const Duration(minutes: 12))),
      ChatMessage(id: 'm32', sender: 'pat', text: 'classic', time: now.subtract(const Duration(minutes: 11))),
      ChatMessage(id: 'm33', sender: 'pat', text: 'the regular one', time: now.subtract(const Duration(minutes: 11))),
      ChatMessage(id: 'm34', sender: 'jamie', text: 'ok so 2 coke, what do the others wanna drink?', time: now.subtract(const Duration(minutes: 10))),
      ChatMessage(id: 'm35', sender: 'alex', text: 'coke for me too pls', time: now.subtract(const Duration(minutes: 9))),
      ChatMessage(id: 'm36', sender: 'sam', text: 'wait how many garlic bread', time: now.subtract(const Duration(minutes: 8))),
      ChatMessage(id: 'm37', sender: 'jamie', text: 'one', time: now.subtract(const Duration(minutes: 7))),
      ChatMessage(id: 'm38', sender: 'pat', text: 'oh yeah I take a water', time: now.subtract(const Duration(minutes: 6))),
      ChatMessage(id: 'm39', sender: 'alex', text: 'should be enough', time: now.subtract(const Duration(minutes: 6))),
      ChatMessage(id: 'm40', sender: 'jamie', text: 'yeah one garlic bread is fine', time: now.subtract(const Duration(minutes: 5))),
      ChatMessage(id: 'm41', sender: 'pat', text: 'ok hurry up now', time: now.subtract(const Duration(minutes: 5))),
      ChatMessage(id: 'm42', sender: 'pat', text: 'i\'m hungry', time: now.subtract(const Duration(minutes: 5))),
    ];

    _shops = _mockShops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FoodShop> _mockShops() {
    final pizzaPlanet = FoodShop(
      id: 'pizza_planet',
      name: 'Pizza Planet',
      emoji: '🪐',
      items: const [
        FoodItem(
          id: 'pp_pepperoni',
          name: 'pepperoni classic',
          type: 'pizza',
          price: 10.0,
          toppings: [
            FoodTopping(id: 'mushroom', name: 'mushroom', defaultIncluded: false),
            FoodTopping(id: 'olives', name: 'olives', defaultIncluded: false),
          ],
          emoji: '🍕',
        ),
        FoodItem(
          id: 'pp_margherita',
          name: 'margherita',
          type: 'pizza',
          price: 9.0,
          toppings: [
            FoodTopping(id: 'basil', name: 'basil', defaultIncluded: true),
          ],
          emoji: '🍕',
        ),
        FoodItem(
          id: 'pp_veggie',
          name: 'veggie delight',
          type: 'pizza',
          price: 11.0,
          toppings: [
            FoodTopping(id: 'mushroom', name: 'mushroom', defaultIncluded: true),
            FoodTopping(id: 'olives', name: 'olives', defaultIncluded: true),
            FoodTopping(id: 'peppers', name: 'peppers', defaultIncluded: true),
          ],
          emoji: '🍕',
        ),
        FoodItem(
          id: 'pp_bbq',
          name: 'bbq chicken',
          type: 'pizza',
          price: 12.0,
          toppings: [
            FoodTopping(id: 'onions', name: 'onions', defaultIncluded: true),
          ],
          emoji: '🍕',
        ),
        FoodItem(
          id: 'pp_hawaiian',
          name: 'hawaiian',
          type: 'pizza',
          price: 11.5,
          toppings: [
            FoodTopping(id: 'pineapple', name: 'pineapple', defaultIncluded: true),
          ],
          emoji: '🍕',
        ),
        FoodItem(id: 'pp_coke', name: 'coke', type: 'drink', price: 2.5, emoji: '🥤'),
        FoodItem(id: 'pp_sprite', name: 'sprite', type: 'drink', price: 2.5, emoji: '🥤'),
        FoodItem(id: 'pp_garlic_bread', name: 'garlic bread', type: 'side', price: 4.0, emoji: '🥖'),
        FoodItem(id: 'pp_wings', name: 'chicken wings', type: 'side', price: 7.0, emoji: '🍗'),
      ],
    );

    final bellaNapoli = FoodShop(
      id: 'bella_napoli',
      name: 'Bella Napoli',
      emoji: '🍕',
      items: const [
        FoodItem(id: 'bn_margherita', name: 'margherita', type: 'pizza', price: 10.0, toppings: [
          FoodTopping(id: 'basil', name: 'basil', defaultIncluded: true),
        ], emoji: '🍕'),
        FoodItem(id: 'bn_pepperoni', name: 'pepperoni classic', type: 'pizza', price: 11.0, toppings: [
          FoodTopping(id: 'mushroom', name: 'mushroom', defaultIncluded: false),
        ], emoji: '🍕'),
        FoodItem(id: 'bn_veggie', name: 'veggie delight', type: 'pizza', price: 12.0, toppings: [
          FoodTopping(id: 'mushroom', name: 'mushroom', defaultIncluded: true),
          FoodTopping(id: 'olives', name: 'olives', defaultIncluded: true),
          FoodTopping(id: 'peppers', name: 'peppers', defaultIncluded: true),
          FoodTopping(id: 'onions', name: 'onions', defaultIncluded: true),
        ], emoji: '🍕'),
        FoodItem(id: 'bn_bbq', name: 'bbq chicken', type: 'pizza', price: 13.0, toppings: [
          FoodTopping(id: 'onions', name: 'onions', defaultIncluded: true),
        ], emoji: '🍕'),
        FoodItem(id: 'bn_quattro', name: 'quattro formaggi', type: 'pizza', price: 13.5, toppings: [], emoji: '🍕'),
        FoodItem(id: 'bn_diavola', name: 'diavola', type: 'pizza', price: 12.5, toppings: [
          FoodTopping(id: 'chili', name: 'chili', defaultIncluded: true),
        ], emoji: '🍕'),
        FoodItem(id: 'bn_coke', name: 'coke', type: 'drink', price: 3.0, emoji: '🥤'),
        FoodItem(id: 'bn_water', name: 'water', type: 'drink', price: 2.0, emoji: '💧'),
        FoodItem(id: 'bn_garlic_bread', name: 'garlic bread', type: 'side', price: 5.0, emoji: '🥖'),
        FoodItem(id: 'bn_bruschetta', name: 'bruschetta', type: 'side', price: 6.0, emoji: '🍞'),
      ],
    );

    final burgerBarn = FoodShop(
      id: 'burger_barn',
      name: 'Burger Barn',
      emoji: '🍔',
      items: const [
        FoodItem(id: 'bb_cheeseburger', name: 'cheeseburger', type: 'burger', price: 8.5, toppings: [
          FoodTopping(id: 'pickles', name: 'pickles', defaultIncluded: true),
          FoodTopping(id: 'onions', name: 'onions', defaultIncluded: true),
        ], emoji: '🍔'),
        FoodItem(id: 'bb_bacon_burger', name: 'bacon burger', type: 'burger', price: 9.5, toppings: [
          FoodTopping(id: 'pickles', name: 'pickles', defaultIncluded: true),
        ], emoji: '🍔'),
        FoodItem(id: 'bb_veggie_burger', name: 'veggie burger', type: 'burger', price: 8.0, toppings: [
          FoodTopping(id: 'mushroom', name: 'mushroom', defaultIncluded: true),
        ], emoji: '🍔'),
        FoodItem(id: 'bb_fries', name: 'fries', type: 'side', price: 3.0, emoji: '🍟'),
        FoodItem(id: 'bb_onion_rings', name: 'onion rings', type: 'side', price: 3.5, emoji: '🧅'),
        FoodItem(id: 'bb_coke', name: 'coke', type: 'drink', price: 2.5, emoji: '🥤'),
        FoodItem(id: 'bb_sprite', name: 'sprite', type: 'drink', price: 2.5, emoji: '🥤'),
        FoodItem(id: 'bb_milkshake', name: 'milkshake', type: 'drink', price: 4.5, emoji: '🍨'),
      ],
    );

    final tacoTown = FoodShop(
      id: 'taco_town',
      name: 'Taco Town',
      emoji: '🌮',
      items: const [
        FoodItem(id: 'tt_chicken_taco', name: 'chicken taco', type: 'taco', price: 3.5, toppings: [
          FoodTopping(id: 'lettuce', name: 'lettuce', defaultIncluded: true),
          FoodTopping(id: 'cheese', name: 'cheese', defaultIncluded: true),
        ], emoji: '🌮'),
        FoodItem(id: 'tt_beef_taco', name: 'beef taco', type: 'taco', price: 3.5, toppings: [
          FoodTopping(id: 'lettuce', name: 'lettuce', defaultIncluded: true),
          FoodTopping(id: 'cheese', name: 'cheese', defaultIncluded: true),
        ], emoji: '🌮'),
        FoodItem(id: 'tt_burrito', name: 'burrito', type: 'burrito', price: 8.0, toppings: [
          FoodTopping(id: 'beans', name: 'beans', defaultIncluded: true),
          FoodTopping(id: 'rice', name: 'rice', defaultIncluded: true),
        ], emoji: '🌯'),
        FoodItem(id: 'tt_nachos', name: 'nachos', type: 'side', price: 5.0, emoji: '🧀'),
        FoodItem(id: 'tt_guac', name: 'guacamole', type: 'side', price: 2.5, emoji: '🥑'),
        FoodItem(id: 'tt_coke', name: 'coke', type: 'drink', price: 2.5, emoji: '🥤'),
        FoodItem(id: 'tt_horchata', name: 'horchata', type: 'drink', price: 3.0, emoji: '🥛'),
      ],
    );

    return [pizzaPlanet, bellaNapoli, burgerBarn, tacoTown];
  }

  void _handlePlaceOrder() {
    final ok = _validateOrder();
    if (ok) {
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      widget.onComplete(LevelOutcome(score: 0));
    }
  }

  bool _validateOrder() {
    if (_selectedShop == null) return false;
    if (_selectedShop!.id != _targetShopId) return false;

    // Expected final order:
    // 1 margherita
    // 2 pepperoni classic
    // 1 veggie delight (no mushrooms)
    // 3 coke
    // 1 water
    // 1 garlic bread
    int mar = 0, pep = 0, vegNoMush = 0, coke = 0, water = 0, garlicBread = 0;
    for (final ci in _cart) {
      switch (ci.item.id) {
        case _margheritaId:
          mar += ci.quantity;
          break;
        case _pepperoniId:
          pep += ci.quantity;
          break;
        case _veggieId:
          final removed = ci.removedToppingIds;
          if (!removed.contains(_mushroomId)) return false; // must be without mushrooms
          vegNoMush += ci.quantity;
          break;
        case _cokeId:
          coke += ci.quantity;
          break;
        case _waterId:
          water += ci.quantity;
          break;
        case _garlicBreadId:
          garlicBread += ci.quantity;
          break;
        default:
          return false; // any extra items fail
      }
    }
    final okCounts = mar == 1 && pep == 2 && vegNoMush == 1 && coke == 3 && water == 1 && garlicBread == 1;
    final totalQty = mar + pep + vegNoMush + coke + water + garlicBread;
    final cartQty = _cart.fold<int>(0, (p, e) => p + e.quantity);
    return okCounts && totalQty == cartQty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          // app switcher only (no back button/header)
          Container(
            color: NunuColors.backgroundPaper,
            padding: const EdgeInsets.only(top: 8),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: NunuColors.primaryMain,
              tabs: const [
                Tab(text: 'chat'),
                Tab(text: 'eats'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Messenger-like tab with higher-contrast background
                ChatHistory(
                  messages: _messages,
                  participants: _people,
                  title: 'pizza night',
                  messageAreaColor: const Color(0xFFE6EBF0),
                  startFromBottom: true,
                  showHeader: false,
                ),

                // Food ordering tab (Uber Eats-like green/white theme)
                Container(
                  color: Color(0xFFE6EBF0),
                  child: Column(
                  children: [
                    Expanded(
                      child: _selectedShop == null
                          ? FoodShopOverview(
                              shops: _shops,
                              onSelect: (s) => setState(() => _selectedShop = s),
                            )
                          : FoodShopDetail(
                              shop: _selectedShop!,
                              onAddToCart: (ci) => setState(() => _cart.add(ci)),
                              onBack: () => setState(() => _selectedShop = null),
                            ),
                    ),
                    FoodCartPanel(
                      items: _cart,
                      onPlaceOrder: _handlePlaceOrder,
                      onClear: () => setState(_cart.clear),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
