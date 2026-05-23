import 'dart:math';

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

class _ExpectedLine {
  const _ExpectedLine({
    required this.itemId,
    required this.quantity,
    this.removedToppings = const {},
  });

  final String itemId;
  final int quantity;
  final Set<String> removedToppings;
}

class _StageConfig {
  const _StageConfig({
    required this.chatTitle,
    required this.targetShopId,
    required this.people,
    required this.messages,
    required this.expected,
  });

  final String chatTitle;
  final String targetShopId;
  final Map<String, ChatParticipant> people;
  final List<ChatMessage> messages;
  final List<_ExpectedLine> expected;

  int get expectedTotal => expected.fold<int>(0, (s, e) => s + e.quantity);
}

class _StageResult {
  const _StageResult({
    required this.correct,
    required this.wrong,
    required this.missing,
    required this.wrongShop,
    required this.score,
  });

  final int correct;
  final int wrong;
  final int missing;
  final bool wrongShop;
  final double score;
}

class LevelGroupOrder extends LevelWidget {
  const LevelGroupOrder({super.key, required super.onComplete});

  @override
  State createState() => _LevelGroupOrderState();
}

class _LevelGroupOrderState extends State<LevelGroupOrder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<FoodShop> _shops;
  late final List<_StageConfig> _stages;

  int _stageIndex = 0;
  FoodShop? _selectedShop;
  final List<CartItem> _cart = [];
  final List<_StageResult> _results = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shops = _mockShops();
    _stages = _buildStages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _StageConfig get _stage => _stages[_stageIndex];

  // ────────────── scoring ──────────────

  String _toppingKey(Set<String> removed) {
    final list = removed.toList()..sort();
    return list.join(',');
  }

  _StageResult _evaluateStage(_StageConfig stage) {
    final wrongShop =
        _selectedShop == null || _selectedShop!.id != stage.targetShopId;

    // aggregate cart by (itemId, removedToppingSet)
    final Map<String, int> cartAgg = {};
    for (final ci in _cart) {
      final key = '${ci.item.id}|${_toppingKey(ci.removedToppingIds)}';
      cartAgg[key] = (cartAgg[key] ?? 0) + ci.quantity;
    }

    int correct = 0;
    int wrong = 0;
    for (final exp in stage.expected) {
      final key = '${exp.itemId}|${_toppingKey(exp.removedToppings)}';
      final got = cartAgg.remove(key) ?? 0;
      final matched = min(got, exp.quantity);
      correct += matched;
      // anything over the expected qty for this exact line is wrong
      if (got > exp.quantity) wrong += got - exp.quantity;
    }
    // any leftover cart aggregates are wrong items / wrong toppings
    for (final qty in cartAgg.values) {
      wrong += qty;
    }
    final missing = stage.expectedTotal - correct;

    double score = stage.expectedTotal == 0
        ? 0
        : ((correct - wrong) / stage.expectedTotal).clamp(0.0, 1.0).toDouble();
    if (score < 0) score = 0;
    if (wrongShop) score *= 0.1;

    return _StageResult(
      correct: correct,
      wrong: wrong,
      missing: missing < 0 ? 0 : missing,
      wrongShop: wrongShop,
      score: score,
    );
  }

  void _handlePlaceOrder() {
    final result = _evaluateStage(_stage);
    _results.add(result);

    if (_stageIndex + 1 >= _stages.length) {
      _finishLevel();
    } else {
      setState(() {
        _stageIndex++;
        _cart.clear();
        _selectedShop = null;
        _tabController.index = 0;
      });
    }
  }

  void _finishLevel() {
    final avg =
        _results.fold<double>(0, (s, r) => s + r.score) / _results.length;
    final correct = _results.fold<int>(0, (s, r) => s + r.correct);
    final wrong = _results.fold<int>(0, (s, r) => s + r.wrong);
    final missing = _results.fold<int>(0, (s, r) => s + r.missing);
    final wrongShops =
        _results.where((r) => r.wrongShop).length;

    widget.onComplete(LevelOutcome(
      score: avg,
      metrics: {
        'correct_items': correct,
        'wrong_items': wrong,
        'missing_items': missing,
        'wrong_shop_stages': wrongShops,
      },
    ));
  }

  // ────────────── shops ──────────────

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

  // ────────────── stages ──────────────

  List<_StageConfig> _buildStages() {
    final now = DateTime.now();
    DateTime t(int stage, int minutesAgo) =>
        now.subtract(Duration(minutes: (stage * 200) + minutesAgo));

    // stage 1: pizza night (original)
    final pizzaPeople = const {
      'alex': ChatParticipant('alex', color: Colors.blue),
      'sam': ChatParticipant('sam', color: Colors.purple),
      'jamie': ChatParticipant('jamie', color: Colors.teal),
      'pat': ChatParticipant('pat', color: Colors.orange),
    };
    final pizzaMsgs = <ChatMessage>[
      ChatMessage(id: 's1m1', sender: 'alex', text: 'what do you guys wanna get for dinner?', time: t(1, 35)),
      ChatMessage(id: 's1m2', sender: 'jamie', text: 'burgers?', time: t(1, 34)),
      ChatMessage(id: 's1m3', sender: 'sam', text: 'burger barn is good', time: t(1, 33)),
      ChatMessage(id: 's1m4', sender: 'pat', text: 'nah I want pizza 🍕', time: t(1, 32)),
      ChatMessage(id: 's1m5', sender: 'alex', text: 'ok pizza it is', time: t(1, 31)),
      ChatMessage(id: 's1m6', sender: 'jamie', text: 'okeyy :((', time: t(1, 30)),
      ChatMessage(id: 's1m6a', sender: 'pat', text: 'btw did u guys see the new spiderman trailer', time: t(1, 30)),
      ChatMessage(id: 's1m6b', sender: 'alex', text: 'nope', time: t(1, 30)),
      ChatMessage(id: 's1m6c', sender: 'pat', text: 'looks sick', time: t(1, 30)),
      ChatMessage(id: 's1m7', sender: 'sam', text: 'pizza planet or bella napoli?', time: t(1, 29)),
      ChatMessage(id: 's1m8', sender: 'pat', text: 'planet is cheaper', time: t(1, 28)),
      ChatMessage(id: 's1m9', sender: 'alex', text: 'yeah but it sucks, bella napoli is so much better', time: t(1, 28)),
      ChatMessage(id: 's1m10', sender: 'jamie', text: 'margherita 🫡', time: t(1, 27)),
      ChatMessage(id: 's1m11', sender: 'alex', text: 'ok sure napoli 😊', time: t(1, 27)),
      ChatMessage(id: 's1m12', sender: 'sam', text: 'pepperoni classic for me', time: t(1, 26)),
      ChatMessage(id: 's1m13', sender: 'pat', text: 'one bbq chicken', time: t(1, 25)),
      ChatMessage(id: 's1m14', sender: 'alex', text: 'veggie delight', time: t(1, 24)),
      ChatMessage(id: 's1m15', sender: 'jamie', text: 'any drinks?', time: t(1, 23)),
      ChatMessage(id: 's1m16', sender: 'jamie', text: 'coke?', time: t(1, 22)),
      ChatMessage(id: 's1m17', sender: 'sam', text: 'yea I take one coke', time: t(1, 21)),
      ChatMessage(id: 's1m18', sender: 'alex', text: 'wait', time: t(1, 20)),
      ChatMessage(id: 's1m19', sender: 'alex', text: 'should I take hawaiian maybe??', time: t(1, 20)),
      ChatMessage(id: 's1m20', sender: 'pat', text: 'bruh ☠️', time: t(1, 19)),
      ChatMessage(id: 's1m21', sender: 'jamie', text: '🤡', time: t(1, 19)),
      ChatMessage(id: 's1m22', sender: 'pat', text: 'pineapple is disgusting', time: t(1, 19)),
      ChatMessage(id: 's1m23', sender: 'alex', text: 'lmao', time: t(1, 18)),
      ChatMessage(id: 's1m23a', sender: 'jamie', text: 'my dog is staring at me rn', time: t(1, 18)),
      ChatMessage(id: 's1m23b', sender: 'jamie', text: 'he knows there will be crusts', time: t(1, 18)),
      ChatMessage(id: 's1m23c', sender: 'sam', text: '🐶', time: t(1, 17)),
      ChatMessage(id: 's1m24', sender: 'sam', text: 'trueee', time: t(1, 17)),
      ChatMessage(id: 's1m25', sender: 'alex', text: 'ok then veggie is fine :/', time: t(1, 17)),
      ChatMessage(id: 's1m26', sender: 'pat', text: 'actually', time: t(1, 16)),
      ChatMessage(id: 's1m27', sender: 'alex', text: 'no mushrooms tho', time: t(1, 16)),
      ChatMessage(id: 's1m28', sender: 'jamie', text: 'any garlic bread enjoyers? 😏', time: t(1, 15)),
      ChatMessage(id: 's1m29', sender: 'pat', text: 'ill take pepperoni instead', time: t(1, 14)),
      ChatMessage(id: 's1m30', sender: 'alex', text: 'oh yeahh garlic bread', time: t(1, 13)),
      ChatMessage(id: 's1m31', sender: 'sam', text: 'which pepperoni', time: t(1, 12)),
      ChatMessage(id: 's1m32', sender: 'pat', text: 'classic', time: t(1, 11)),
      ChatMessage(id: 's1m33', sender: 'pat', text: 'the regular one', time: t(1, 11)),
      ChatMessage(id: 's1m34', sender: 'jamie', text: 'ok so 2 coke, what do the others wanna drink?', time: t(1, 10)),
      ChatMessage(id: 's1m35', sender: 'alex', text: 'coke for me too pls', time: t(1, 9)),
      ChatMessage(id: 's1m36', sender: 'sam', text: 'wait how many garlic bread', time: t(1, 8)),
      ChatMessage(id: 's1m37', sender: 'jamie', text: 'one', time: t(1, 7)),
      ChatMessage(id: 's1m37a', sender: 'sam', text: 'are we still going bowling on saturday btw', time: t(1, 7)),
      ChatMessage(id: 's1m37b', sender: 'alex', text: 'ye 7pm', time: t(1, 7)),
      ChatMessage(id: 's1m37c', sender: 'jamie', text: 'cool', time: t(1, 7)),
      ChatMessage(id: 's1m38', sender: 'pat', text: 'oh yeah I take a water', time: t(1, 6)),
      ChatMessage(id: 's1m39', sender: 'alex', text: 'should be enough', time: t(1, 6)),
      ChatMessage(id: 's1m40', sender: 'jamie', text: 'yeah one garlic bread is fine', time: t(1, 5)),
      ChatMessage(id: 's1m41', sender: 'pat', text: 'ok hurry up now', time: t(1, 5)),
      ChatMessage(id: 's1m42', sender: 'pat', text: "i'm hungry", time: t(1, 5)),
    ];
    final pizzaExpected = const [
      _ExpectedLine(itemId: 'bn_margherita', quantity: 1),
      _ExpectedLine(itemId: 'bn_pepperoni', quantity: 2),
      _ExpectedLine(itemId: 'bn_veggie', quantity: 1, removedToppings: {'mushroom'}),
      _ExpectedLine(itemId: 'bn_coke', quantity: 3),
      _ExpectedLine(itemId: 'bn_water', quantity: 1),
      _ExpectedLine(itemId: 'bn_garlic_bread', quantity: 1),
    ];

    // stage 2: taco tuesday — conditional orders, cascading reversals
    final tacoPeople = const {
      'maya': ChatParticipant('maya', color: Colors.pink),
      'leo': ChatParticipant('leo', color: Colors.indigo),
      'kai': ChatParticipant('kai', color: Colors.green),
      'zoe': ChatParticipant('zoe', color: Colors.amber),
    };
    final tacoMsgs = <ChatMessage>[
      ChatMessage(id: 's2m1', sender: 'maya', text: 'taco tuesday lets gooo', time: t(2, 50)),
      ChatMessage(id: 's2m2', sender: 'leo', text: 'where? taco town?', time: t(2, 49)),
      ChatMessage(id: 's2m3', sender: 'kai', text: 'obviously', time: t(2, 49)),
      ChatMessage(id: 's2m3a', sender: 'leo', text: 'i drove past one called taco palace yesterday', time: t(2, 49)),
      ChatMessage(id: 's2m3b', sender: 'leo', text: 'kinda funny name', time: t(2, 49)),
      ChatMessage(id: 's2m3c', sender: 'kai', text: 'sounds mid tho', time: t(2, 48)),
      ChatMessage(id: 's2m4', sender: 'zoe', text: 'ok 2 beef tacos for me', time: t(2, 48)),
      ChatMessage(id: 's2m5', sender: 'maya', text: 'chicken for me', time: t(2, 47)),
      ChatMessage(id: 's2m6', sender: 'leo', text: 'same as zoe', time: t(2, 47)),
      ChatMessage(id: 's2m7', sender: 'kai', text: 'chicken for me too', time: t(2, 46)),
      ChatMessage(id: 's2m8', sender: 'zoe', text: 'actually wait', time: t(2, 45)),
      ChatMessage(id: 's2m9', sender: 'zoe', text: 'just one taco. chicken not beef', time: t(2, 45)),
      ChatMessage(id: 's2m10', sender: 'maya', text: 'lol changed your mind', time: t(2, 44)),
      ChatMessage(id: 's2m11', sender: 'zoe', text: 'yeah idk im not that hungry', time: t(2, 44)),
      ChatMessage(id: 's2m12', sender: 'kai', text: 'so leo is chicken too then?', time: t(2, 43)),
      ChatMessage(id: 's2m13', sender: 'leo', text: 'i said same as zoe so yeah chicken', time: t(2, 43)),
      ChatMessage(id: 's2m14', sender: 'kai', text: 'bruh', time: t(2, 42)),
      ChatMessage(id: 's2m15', sender: 'zoe', text: 'sry 😅', time: t(2, 42)),
      ChatMessage(id: 's2m15a', sender: 'maya', text: 'wait did anyone watch the game last night', time: t(2, 42)),
      ChatMessage(id: 's2m15b', sender: 'kai', text: 'painful', time: t(2, 41)),
      ChatMessage(id: 's2m15c', sender: 'leo', text: 'we got robbed by the ref fr', time: t(2, 41)),
      ChatMessage(id: 's2m15d', sender: 'kai', text: 'absolutely', time: t(2, 41)),
      ChatMessage(id: 's2m16', sender: 'maya', text: 'anyway no cheese on mine pls. dairy', time: t(2, 41)),
      ChatMessage(id: 's2m17', sender: 'zoe', text: 'cheese is fine for me', time: t(2, 40)),
      ChatMessage(id: 's2m18', sender: 'kai', text: 'cheese yes', time: t(2, 40)),
      ChatMessage(id: 's2m19', sender: 'leo', text: 'cheese ok', time: t(2, 39)),
      ChatMessage(id: 's2m20', sender: 'maya', text: 'should we get a burrito to share?', time: t(2, 38)),
      ChatMessage(id: 's2m21', sender: 'kai', text: 'yes burrito', time: t(2, 38)),
      ChatMessage(id: 's2m22', sender: 'leo', text: 'no beans tho. beans wreck me 💀', time: t(2, 37)),
      ChatMessage(id: 's2m23', sender: 'zoe', text: 'tmi', time: t(2, 37)),
      ChatMessage(id: 's2m23a', sender: 'kai', text: 'beans beans the magical fruit', time: t(2, 37)),
      ChatMessage(id: 's2m23b', sender: 'maya', text: 'the more you eat the more you 🎺', time: t(2, 37)),
      ChatMessage(id: 's2m23c', sender: 'leo', text: 'exactly why no beans on mine', time: t(2, 36)),
      ChatMessage(id: 's2m23d', sender: 'kai', text: '🫘🫘🫘', time: t(2, 36)),
      ChatMessage(id: 's2m24', sender: 'maya', text: 'lol', time: t(2, 36)),
      ChatMessage(id: 's2m24a', sender: 'kai', text: '6 7', time: t(2, 36)),
      ChatMessage(id: 's2m24b', sender: 'zoe', text: 'STOP', time: t(2, 36)),
      ChatMessage(id: 's2m24c', sender: 'leo', text: '6️⃣7️⃣', time: t(2, 35)),
      ChatMessage(id: 's2m24d', sender: 'zoe', text: 'i will leave this chat', time: t(2, 35)),
      ChatMessage(id: 's2m25', sender: 'maya', text: 'drinks?', time: t(2, 35)),
      ChatMessage(id: 's2m26', sender: 'kai', text: 'coke for me', time: t(2, 34)),
      ChatMessage(id: 's2m27', sender: 'zoe', text: 'coke', time: t(2, 34)),
      ChatMessage(id: 's2m28', sender: 'leo', text: 'horchata if they have it. otherwise coke', time: t(2, 33)),
      ChatMessage(id: 's2m29', sender: 'maya', text: 'they have horchata', time: t(2, 33)),
      ChatMessage(id: 's2m30', sender: 'leo', text: 'horchata then 🥛', time: t(2, 32)),
      ChatMessage(id: 's2m31', sender: 'maya', text: "i'll just take water", time: t(2, 31)),
      ChatMessage(id: 's2m32', sender: 'zoe', text: "they don't have water", time: t(2, 31)),
      ChatMessage(id: 's2m33', sender: 'maya', text: 'oh', time: t(2, 30)),
      ChatMessage(id: 's2m34', sender: 'maya', text: 'nothing then', time: t(2, 30)),
      ChatMessage(id: 's2m35', sender: 'kai', text: 'actually scratch my coke', time: t(2, 29)),
      ChatMessage(id: 's2m36', sender: 'kai', text: 'had too much soda today', time: t(2, 29)),
      ChatMessage(id: 's2m37', sender: 'zoe', text: 'guac?', time: t(2, 28)),
      ChatMessage(id: 's2m38', sender: 'leo', text: 'one guac to share', time: t(2, 27)),
      ChatMessage(id: 's2m39', sender: 'maya', text: 'place it', time: t(2, 26)),
    ];
    // tally for stage 2:
    //   chicken_taco no-cheese: maya = 1
    //   chicken_taco default:  zoe, kai, leo = 3
    //   burrito no beans:      1
    //   horchata:              leo = 1
    //   coke:                  zoe = 1   (kai cancelled, maya nothing)
    //   guac:                  1
    final tacoExpected = const [
      _ExpectedLine(itemId: 'tt_chicken_taco', quantity: 1, removedToppings: {'cheese'}),
      _ExpectedLine(itemId: 'tt_chicken_taco', quantity: 3),
      _ExpectedLine(itemId: 'tt_burrito', quantity: 1, removedToppings: {'beans'}),
      _ExpectedLine(itemId: 'tt_horchata', quantity: 1),
      _ExpectedLine(itemId: 'tt_coke', quantity: 1),
      _ExpectedLine(itemId: 'tt_guac', quantity: 1),
    ];

    // stage 3: burger run — 6 people, distractors, trades, cancellations
    final burgerPeople = const {
      'noah': ChatParticipant('noah', color: Colors.blue),
      'mia': ChatParticipant('mia', color: Colors.pink),
      'jay': ChatParticipant('jay', color: Colors.brown),
      'ria': ChatParticipant('ria', color: Colors.purple),
      'finn': ChatParticipant('finn', color: Colors.teal),
      'ash': ChatParticipant('ash', color: Colors.orange),
    };
    final burgerMsgs = <ChatMessage>[
      ChatMessage(id: 's3m1', sender: 'noah', text: 'burger barn night 🍔', time: t(3, 60)),
      ChatMessage(id: 's3m2', sender: 'mia', text: 'ugh i wanted pizza', time: t(3, 59)),
      ChatMessage(id: 's3m3', sender: 'jay', text: 'outvoted lol', time: t(3, 59)),
      ChatMessage(id: 's3m3a', sender: 'ash', text: 'guys whats the score', time: t(3, 59)),
      ChatMessage(id: 's3m3b', sender: 'finn', text: '6 7', time: t(3, 58)),
      ChatMessage(id: 's3m3c', sender: 'ash', text: 'i hate it here', time: t(3, 58)),
      ChatMessage(id: 's3m3d', sender: 'noah', text: '💀💀💀', time: t(3, 58)),
      ChatMessage(id: 's3m4', sender: 'ria', text: 'ok focus. cheeseburger for me, hold the pickles', time: t(3, 58)),
      ChatMessage(id: 's3m5', sender: 'finn', text: 'bacon burger', time: t(3, 57)),
      ChatMessage(id: 's3m6', sender: 'ash', text: 'ill take a veggie burger', time: t(3, 57)),
      ChatMessage(id: 's3m7', sender: 'noah', text: 'cheese for me too', time: t(3, 56)),
      ChatMessage(id: 's3m8', sender: 'mia', text: 'double bacon for me', time: t(3, 55)),
      ChatMessage(id: 's3m9', sender: 'jay', text: "they don't have double bacon bro", time: t(3, 55)),
      ChatMessage(id: 's3m10', sender: 'mia', text: 'rly', time: t(3, 54)),
      ChatMessage(id: 's3m11', sender: 'jay', text: 'just the regular bacon burger', time: t(3, 54)),
      ChatMessage(id: 's3m12', sender: 'mia', text: 'hmm', time: t(3, 53)),
      ChatMessage(id: 's3m13', sender: 'mia', text: 'ok same as ria then', time: t(3, 53)),
      ChatMessage(id: 's3m14', sender: 'ria', text: 'pickles off for both ok? gross', time: t(3, 52)),
      ChatMessage(id: 's3m15', sender: 'mia', text: 'yeah no pickles', time: t(3, 51)),
      ChatMessage(id: 's3m16', sender: 'noah', text: "ill do no pickles too, lazy to argue", time: t(3, 51)),
      ChatMessage(id: 's3m17', sender: 'jay', text: 'bacon burger for me, regular', time: t(3, 50)),
      ChatMessage(id: 's3m18', sender: 'finn', text: 'wait actually', time: t(3, 49)),
      ChatMessage(id: 's3m19', sender: 'finn', text: 'veggie burger sounds better', time: t(3, 49)),
      ChatMessage(id: 's3m20', sender: 'finn', text: 'change me to veggie', time: t(3, 48)),
      ChatMessage(id: 's3m21', sender: 'ash', text: 'bro that was MY order', time: t(3, 48)),
      ChatMessage(id: 's3m22', sender: 'finn', text: 'chill we can both get one', time: t(3, 47)),
      ChatMessage(id: 's3m23', sender: 'ash', text: 'hmm', time: t(3, 47)),
      ChatMessage(id: 's3m24', sender: 'ash', text: 'actually nvm im gonna skip the burger', time: t(3, 46)),
      ChatMessage(id: 's3m25', sender: 'ash', text: 'just sides for me', time: t(3, 46)),
      ChatMessage(id: 's3m26', sender: 'noah', text: 'alright. mushrooms on the veggie?', time: t(3, 45)),
      ChatMessage(id: 's3m27', sender: 'finn', text: 'no mushrooms pls', time: t(3, 45)),
      ChatMessage(id: 's3m28', sender: 'ash', text: 'lmao so picky', time: t(3, 44)),
      ChatMessage(id: 's3m28a', sender: 'jay', text: 'wait have any of you played the new zelda', time: t(3, 44)),
      ChatMessage(id: 's3m28b', sender: 'finn', text: 'omg yes its insane', time: t(3, 44)),
      ChatMessage(id: 's3m28c', sender: 'noah', text: 'no spoilers pls', time: t(3, 43)),
      ChatMessage(id: 's3m28d', sender: 'jay', text: 'ok ok', time: t(3, 43)),
      ChatMessage(id: 's3m28e', sender: 'finn', text: 'rated 67/100 btw', time: t(3, 43)),
      ChatMessage(id: 's3m28f', sender: 'ash', text: '...', time: t(3, 43)),
      ChatMessage(id: 's3m28g', sender: 'ria', text: 'finn i swear to god', time: t(3, 43)),
      ChatMessage(id: 's3m29', sender: 'noah', text: 'drinks?', time: t(3, 43)),
      ChatMessage(id: 's3m30', sender: 'ria', text: 'coke', time: t(3, 42)),
      ChatMessage(id: 's3m31', sender: 'noah', text: 'ill take a milkshake', time: t(3, 42)),
      ChatMessage(id: 's3m32', sender: 'finn', text: 'ooo milkshake sounds great. can i?', time: t(3, 41)),
      ChatMessage(id: 's3m33', sender: 'noah', text: 'we can order one each', time: t(3, 40)),
      ChatMessage(id: 's3m34', sender: 'finn', text: 'nah just one is enough', time: t(3, 40)),
      ChatMessage(id: 's3m35', sender: 'finn', text: 'ill take it, you get coke', time: t(3, 39)),
      ChatMessage(id: 's3m36', sender: 'noah', text: 'deal 🤝', time: t(3, 39)),
      ChatMessage(id: 's3m37', sender: 'jay', text: 'water for me', time: t(3, 38)),
      ChatMessage(id: 's3m38', sender: 'jay', text: 'wait they sell water?', time: t(3, 38)),
      ChatMessage(id: 's3m39', sender: 'ria', text: 'nope', time: t(3, 37)),
      ChatMessage(id: 's3m40', sender: 'jay', text: 'nothing for me drink-wise then', time: t(3, 37)),
      ChatMessage(id: 's3m41', sender: 'mia', text: 'hmm', time: t(3, 36)),
      ChatMessage(id: 's3m42', sender: 'mia', text: 'actually', time: t(3, 36)),
      ChatMessage(id: 's3m43', sender: 'mia', text: 'im not even hungry anymore', time: t(3, 35)),
      ChatMessage(id: 's3m44', sender: 'mia', text: 'skip my whole order pls', time: t(3, 35)),
      ChatMessage(id: 's3m45', sender: 'ria', text: 'srsly', time: t(3, 34)),
      ChatMessage(id: 's3m46', sender: 'mia', text: 'ate too many chips earlier', time: t(3, 34)),
      ChatMessage(id: 's3m47', sender: 'ria', text: 'smh', time: t(3, 33)),
      ChatMessage(id: 's3m47a', sender: 'jay', text: 'the lettuce in my burger king burger is the one I stand on', time: t(3, 33)),
      ChatMessage(id: 's3m47b', sender: 'finn', text: 'NOT this again', time: t(3, 33)),
      ChatMessage(id: 's3m47c', sender: 'ria', text: 'foot lettuce 😭', time: t(3, 33)),
      ChatMessage(id: 's3m47d', sender: 'ash', text: 'a 2017 classic', time: t(3, 32)),
      ChatMessage(id: 's3m47e', sender: 'noah', text: 'glad we are not at burger king then', time: t(3, 32)),
      ChatMessage(id: 's3m48', sender: 'noah', text: 'sides?', time: t(3, 32)),
      ChatMessage(id: 's3m49', sender: 'ria', text: 'ill grab a fries to share', time: t(3, 32)),
      ChatMessage(id: 's3m50', sender: 'ash', text: 'onion rings for me', time: t(3, 31)),
      ChatMessage(id: 's3m51', sender: 'finn', text: 'lets place it', time: t(3, 30)),
      ChatMessage(id: 's3m52', sender: 'jay', text: '🤝', time: t(3, 30)),
    ];
    // tally for stage 3:
    //   cheeseburger no pickles: noah + ria = 2 (mia cancelled)
    //   bacon burger:            jay = 1 (finn switched)
    //   veggie burger no mushroom: finn = 1 (ash dropped)
    //   fries:                   1 to share
    //   onion rings:             ash = 1
    //   coke:                    noah (after trade) + ria = 2
    //   milkshake:               finn = 1
    final burgerExpected = const [
      _ExpectedLine(itemId: 'bb_cheeseburger', quantity: 2, removedToppings: {'pickles'}),
      _ExpectedLine(itemId: 'bb_bacon_burger', quantity: 1),
      _ExpectedLine(itemId: 'bb_veggie_burger', quantity: 1, removedToppings: {'mushroom'}),
      _ExpectedLine(itemId: 'bb_fries', quantity: 1),
      _ExpectedLine(itemId: 'bb_onion_rings', quantity: 1),
      _ExpectedLine(itemId: 'bb_coke', quantity: 2),
      _ExpectedLine(itemId: 'bb_milkshake', quantity: 1),
    ];

    return [
      _StageConfig(
        chatTitle: 'pizza night',
        targetShopId: 'bella_napoli',
        people: pizzaPeople,
        messages: pizzaMsgs,
        expected: pizzaExpected,
      ),
      _StageConfig(
        chatTitle: 'taco tuesday',
        targetShopId: 'taco_town',
        people: tacoPeople,
        messages: tacoMsgs,
        expected: tacoExpected,
      ),
      _StageConfig(
        chatTitle: 'burger run',
        targetShopId: 'burger_barn',
        people: burgerPeople,
        messages: burgerMsgs,
        expected: burgerExpected,
      ),
    ];
  }

  // ────────────── ui ──────────────

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          Container(
            color: NunuColors.backgroundPaper,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'order ${_stageIndex + 1} / ${_stages.length} · ${stage.chatTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: NunuColors.primaryMain,
                  tabs: const [
                    Tab(text: 'chat'),
                    Tab(text: 'eats'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ChatHistory(
                  key: ValueKey('chat_$_stageIndex'),
                  messages: stage.messages,
                  participants: stage.people,
                  title: stage.chatTitle,
                  messageAreaColor: const Color(0xFFE6EBF0),
                  startFromBottom: true,
                  showHeader: false,
                ),
                Container(
                  color: const Color(0xFFE6EBF0),
                  child: Column(
                    children: [
                      Expanded(
                        child: _selectedShop == null
                            ? FoodShopOverview(
                                shops: _shops,
                                onSelect: (s) =>
                                    setState(() => _selectedShop = s),
                              )
                            : FoodShopDetail(
                                shop: _selectedShop!,
                                onAddToCart: (ci) =>
                                    setState(() => _cart.add(ci)),
                                onBack: () =>
                                    setState(() => _selectedShop = null),
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
