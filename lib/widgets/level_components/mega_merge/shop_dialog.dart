import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

/// Shop item data
class ShopItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int price;
  final ShopCategory category;
  final Color? color;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    required this.category,
    this.color,
  });
}

enum ShopCategory { coins, energy, boosters, cosmetics }

/// Full shop dialog with tabs
class ShopDialog extends StatefulWidget {
  final int currentCoins;
  final int currentEnergy;
  final int maxEnergy;
  final Set<String> ownedCosmetics;
  final Set<String> claimedCoinPacks;
  final Function(String packId, int coins) onClaimCoins;
  final Function(int energy) onBuyEnergy;
  final Function(String boosterId) onBuyBooster;
  final Function(String cosmeticId) onBuyCosmetic;

  const ShopDialog({
    Key? key,
    required this.currentCoins,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.ownedCosmetics,
    required this.claimedCoinPacks,
    required this.onClaimCoins,
    required this.onBuyEnergy,
    required this.onBuyBooster,
    required this.onBuyCosmetic,
  }) : super(key: key);

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _localCoins = 0;

  static const List<ShopItem> _coinPacks = [
    ShopItem(
      id: 'coins_100',
      name: '100 coins',
      description: 'starter pack',
      icon: Icons.monetization_on,
      price: 0, // Real money simulation
      category: ShopCategory.coins,
      color: Colors.amber,
    ),
    ShopItem(
      id: 'coins_500',
      name: '500 coins',
      description: 'best value!',
      icon: Icons.monetization_on,
      price: 0,
      category: ShopCategory.coins,
      color: Colors.amber,
    ),
    ShopItem(
      id: 'coins_1000',
      name: '1000 coins',
      description: 'whale pack',
      icon: Icons.monetization_on,
      price: 0,
      category: ShopCategory.coins,
      color: Colors.amber,
    ),
  ];

  static const List<ShopItem> _energyPacks = [
    ShopItem(
      id: 'energy_10',
      name: '+10 energy',
      description: 'quick refill',
      icon: Icons.flash_on,
      price: 50,
      category: ShopCategory.energy,
      color: Colors.yellow,
    ),
    ShopItem(
      id: 'energy_50',
      name: '+50 energy',
      description: 'power up',
      icon: Icons.flash_on,
      price: 200,
      category: ShopCategory.energy,
      color: Colors.yellow,
    ),
    ShopItem(
      id: 'energy_full',
      name: 'full refill',
      description: 'max energy',
      icon: Icons.battery_charging_full,
      price: 300,
      category: ShopCategory.energy,
      color: Colors.green,
    ),
  ];

  static const List<ShopItem> _boosters = [
    ShopItem(
      id: 'boost_speed',
      name: 'speed boost',
      description: '2x spawn rate for 30s',
      icon: Icons.speed,
      price: 100,
      category: ShopCategory.boosters,
      color: Colors.orange,
    ),
    ShopItem(
      id: 'boost_auto',
      name: 'auto-merge',
      description: 'auto-merge tier 1 items',
      icon: Icons.autorenew,
      price: 150,
      category: ShopCategory.boosters,
      color: Colors.cyan,
    ),
    ShopItem(
      id: 'boost_extra',
      name: 'extra spawn',
      description: 'spawn 2 items at once',
      icon: Icons.add_circle,
      price: 75,
      category: ShopCategory.boosters,
      color: Colors.purple,
    ),
  ];

  static const List<ShopItem> _cosmetics = [
    ShopItem(
      id: 'theme_neon',
      name: 'neon theme',
      description: 'glowing neon items',
      icon: Icons.lightbulb,
      price: 500,
      category: ShopCategory.cosmetics,
      color: Colors.pink,
    ),
    ShopItem(
      id: 'theme_gold',
      name: 'gold theme',
      description: 'luxurious gold items',
      icon: Icons.star,
      price: 750,
      category: ShopCategory.cosmetics,
      color: Colors.amber,
    ),
    ShopItem(
      id: 'theme_ice',
      name: 'ice theme',
      description: 'frozen crystal look',
      icon: Icons.ac_unit,
      price: 600,
      category: ShopCategory.cosmetics,
      color: Colors.lightBlue,
    ),
    ShopItem(
      id: 'skin_robot',
      name: 'robot skin',
      description: 'mechanical item style',
      icon: Icons.smart_toy,
      price: 400,
      category: ShopCategory.cosmetics,
      color: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _localCoins = widget.currentCoins;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _buyItem(ShopItem item) {
    HapticFeedback.mediumImpact();
    
    switch (item.category) {
      case ShopCategory.coins:
        if (widget.claimedCoinPacks.contains(item.id)) {
          _showPaywalled();
          return;
        }
        final amount = item.id == 'coins_100'
            ? 100
            : item.id == 'coins_500'
                ? 500
                : 1000;
        widget.onClaimCoins(item.id, amount);
        setState(() => _localCoins += amount);
        _showPurchaseSuccess('+$amount coins!');
        break;
        
      case ShopCategory.energy:
        if (_localCoins < item.price) {
          _showInsufficientFunds();
          return;
        }
        final amount = item.id == 'energy_10'
            ? 10
            : item.id == 'energy_50'
                ? 50
                : widget.maxEnergy;
        widget.onBuyEnergy(amount);
        setState(() => _localCoins -= item.price);
        _showPurchaseSuccess('+$amount energy!');
        break;
        
      case ShopCategory.boosters:
        if (_localCoins < item.price) {
          _showInsufficientFunds();
          return;
        }
        widget.onBuyBooster(item.id);
        setState(() => _localCoins -= item.price);
        _showPurchaseSuccess('${item.name} activated!');
        break;
        
      case ShopCategory.cosmetics:
        if (widget.ownedCosmetics.contains(item.id)) {
          _showAlreadyOwned();
          return;
        }
        if (_localCoins < item.price) {
          _showInsufficientFunds();
          return;
        }
        widget.onBuyCosmetic(item.id);
        setState(() => _localCoins -= item.price);
        _showPurchaseSuccess('${item.name} unlocked!');
        break;
    }
  }

  void _showPurchaseSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NunuColors.successMain,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showPaywalled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('one-time free only — pay \$ to get more'),
        backgroundColor: NunuColors.warningMain,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showInsufficientFunds() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('not enough coins!'),
        backgroundColor: NunuColors.errorMain,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAlreadyOwned() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('already owned!'),
        backgroundColor: NunuColors.warningMain,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      appBar: AppBar(
        backgroundColor: NunuColors.backgroundPaper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text('shop', style: TextStyle(color: Colors.white)),
            const Spacer(),
            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Text(
              '$_localCoins',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NunuColors.primaryMain,
          labelColor: NunuColors.primaryMain,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.monetization_on), text: 'coins'),
            Tab(icon: Icon(Icons.flash_on), text: 'energy'),
            Tab(icon: Icon(Icons.rocket_launch), text: 'boosters'),
            Tab(icon: Icon(Icons.palette), text: 'cosmetics'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildItemGrid(_coinPacks, isCoinPack: true),
              _buildItemGrid(_energyPacks),
              _buildItemGrid(_boosters),
              _buildItemGrid(_cosmetics),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemGrid(List<ShopItem> items, {bool isCoinPack = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = widget.ownedCosmetics.contains(item.id);
        final isClaimedCoin =
            isCoinPack && widget.claimedCoinPacks.contains(item.id);
        final canAfford = isCoinPack || _localCoins >= item.price;
        
        return GestureDetector(
          onTap: () => _buyItem(item),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwned
                    ? NunuColors.successMain
                    : canAfford
                        ? (item.color ?? NunuColors.primaryMain).withOpacity(0.5)
                        : Colors.white24,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  color: item.color ?? NunuColors.primaryMain,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (isOwned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NunuColors.successMain.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'owned',
                      style: TextStyle(
                        color: NunuColors.successMain,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isCoinPack && !isClaimedCoin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NunuColors.successMain,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'free',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isCoinPack && isClaimedCoin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'pay \$',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? NunuColors.primaryMain
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color: canAfford ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

