import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'play_store_data.dart';

/// Mock Play Store app
class PlayStoreApp extends StatefulWidget {
  final Set<String> installedApps;
  final bool megaMergeUpdated;
  final Function(StoreApp) onInstallApp;
  final Function(StoreApp) onUpdateApp;
  final Function(String) onUninstallApp;
  final VoidCallback onBack;

  /// Optional app ID to open directly to that app's detail page
  final String? initialAppId;

  const PlayStoreApp({
    Key? key,
    required this.installedApps,
    required this.megaMergeUpdated,
    required this.onInstallApp,
    required this.onUpdateApp,
    required this.onUninstallApp,
    required this.onBack,
    this.initialAppId,
  }) : super(key: key);

  @override
  State<PlayStoreApp> createState() => _PlayStoreAppState();
}

class _PlayStoreAppState extends State<PlayStoreApp> {
  int _headerTabIndex = 0;
  int _footerTabIndex = 1; // Start on "Apps" tab
  StoreApp? _selectedApp;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _showMyApps = false;

  @override
  void initState() {
    super.initState();
    // If initialAppId is provided, navigate directly to that app's detail page
    if (widget.initialAppId != null) {
      final app = allStoreApps
          .where((a) => a.id == widget.initialAppId)
          .firstOrNull;
      if (app != null) {
        _selectedApp = app;
      }
    }
  }

  final List<String> _headerTabs = [
    'for you',
    'top charts',
    'kids',
    'categories',
  ];
  final List<(IconData, String)> _footerTabs = [
    (Icons.games, 'games'),
    (Icons.apps, 'apps'),
    (Icons.search, 'search'),
    (Icons.book, 'books'),
    (Icons.person, 'you'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedApp != null) {
      return _buildAppDetailPage(_selectedApp!);
    }

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearching) _buildSearchBar(),
            if (!_isSearching) _buildHeaderTabs(),
            Expanded(child: _buildContent()),
            _buildFooterNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: NunuColors.backgroundPaper,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          const Expanded(
            child: Text(
              'Play Store',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: NunuColors.backgroundPaper,
      child: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'search apps & games',
          hintStyle: const TextStyle(color: NunuColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: NunuColors.textSecondary),
          filled: true,
          fillColor: NunuColors.backgroundDefault,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildHeaderTabs() {
    return Container(
      color: NunuColors.backgroundPaper,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List.generate(_headerTabs.length, (index) {
            final isSelected = _headerTabIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _headerTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? NunuColors.primaryMain
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _headerTabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? NunuColors.primaryMain
                        : NunuColors.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showMyApps) {
      return _buildMyAppsScreen();
    }

    if (_isSearching && _searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Footer tab takes priority
    switch (_footerTabIndex) {
      case 0: // Games
        return _buildGamesList();
      case 1: // Apps
        return _buildAppsList();
      case 2: // Search
        return _buildSearchPrompt();
      case 3: // Books
        return _buildBooksTab();
      case 4: // You
        return _buildYouTab();
      default:
        return _buildAppList(allStoreApps);
    }
  }

  /// Games tab - shows content based on header tab selection
  Widget _buildGamesList() {
    switch (_headerTabIndex) {
      case 0: // For you
        return _buildAppList(
          getFeaturedApps()
              .where((a) => a.category == AppCategory.games)
              .toList(),
        );
      case 1: // Top charts
        return _buildAppList(
          getTopRatedApps(
            limit: 30,
          ).where((a) => a.category == AppCategory.games).toList(),
        );
      case 2: // Kids
        return _buildAppList(
          getKidsApps().where((a) => a.category == AppCategory.games).toList(),
        );
      case 3: // Categories
        return _buildCategoriesTab(filterGames: true);
      default:
        return _buildAppList(getAppsByCategory(AppCategory.games));
    }
  }

  /// Apps tab - shows content based on header tab selection
  Widget _buildAppsList() {
    switch (_headerTabIndex) {
      case 0: // For you
        return _buildAppList(
          getFeaturedApps()
              .where((a) => a.category == AppCategory.apps)
              .toList(),
        );
      case 1: // Top charts
        return _buildAppList(
          getTopRatedApps(
            limit: 30,
          ).where((a) => a.category == AppCategory.apps).toList(),
        );
      case 2: // Kids
        return _buildAppList(
          getKidsApps().where((a) => a.category == AppCategory.apps).toList(),
        );
      case 3: // Categories
        return _buildCategoriesTab(filterGames: false);
      default:
        return _buildAppList(getAppsByCategory(AppCategory.apps));
    }
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: NunuColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'search for apps & games',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isSearching = true),
            child: const Text(
              'tap to search',
              style: TextStyle(color: NunuColors.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = allStoreApps
        .where(
          (app) =>
              app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.developer.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: NunuColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'no results for "$_searchQuery"',
              style: const TextStyle(color: NunuColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return _buildAppList(results);
  }

  Widget _buildAppList(List<StoreApp> apps) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return _buildAppListItem(apps[index]);
      },
    );
  }

  Widget _buildAppListItem(StoreApp app) {
    final isInstalled = widget.installedApps.contains(app.id);
    final needsUpdate = app.id == 'mega_merge' && !widget.megaMergeUpdated;

    return GestureDetector(
      onTap: () => setState(() => _selectedApp = app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: app.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(app.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.developer,
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        app.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        app.downloads,
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildInstallButton(app, isInstalled, needsUpdate),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallButton(StoreApp app, bool isInstalled, bool needsUpdate) {
    if (needsUpdate) {
      return ElevatedButton(
        onPressed: () => widget.onUpdateApp(app),
        style: ElevatedButton.styleFrom(
          backgroundColor: NunuColors.primaryMain,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'update',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      );
    }

    if (isInstalled) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: NunuColors.textSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'installed',
          style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => widget.onInstallApp(app),
      style: ElevatedButton.styleFrom(
        backgroundColor: NunuColors.successMain,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'install',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildBooksTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: NunuColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'books coming soon',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: NunuColors.primaryMain,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Guest User', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Sign in for more features',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
          ),
          const Divider(color: NunuColors.backgroundPaper),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('My apps', style: TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.installedApps.length}',
                  style: const TextStyle(color: NunuColors.textSecondary),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: NunuColors.textSecondary,
                ),
              ],
            ),
            onTap: () => setState(() => _showMyApps = true),
          ),
          const ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('Settings', style: TextStyle(color: Colors.white)),
          ),
          const ListTile(
            leading: Icon(Icons.help, color: Colors.white),
            title: Text(
              'Help & feedback',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAppsScreen() {
    // Get installed apps from store data
    final installedAppsList = allStoreApps
        .where((app) => widget.installedApps.contains(app.id))
        .toList();

    return Column(
      children: [
        // Sub-header for My Apps
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: NunuColors.backgroundPaper,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showMyApps = false),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'My apps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: installedAppsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apps,
                        size: 64,
                        color: NunuColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'no apps installed yet',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _showMyApps = false;
                          _footerTabIndex = 1;
                        }),
                        child: const Text(
                          'browse apps',
                          style: TextStyle(color: NunuColors.primaryMain),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: installedAppsList.length,
                  itemBuilder: (context, index) {
                    return _buildInstalledAppItem(installedAppsList[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInstalledAppItem(StoreApp app) {
    final needsUpdate = app.id == 'mega_merge' && !widget.megaMergeUpdated;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(app.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  app.developer,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (needsUpdate) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: NunuColors.warningMain.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'update available',
                      style: TextStyle(
                        color: NunuColors.warningMain,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (needsUpdate)
            ElevatedButton(
              onPressed: () => widget.onUpdateApp(app),
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'update',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => _showUninstallConfirmation(app),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NunuColors.errorMain),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'uninstall',
                style: TextStyle(color: NunuColors.errorMain, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _showUninstallConfirmation(StoreApp app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        title: Text(
          'Uninstall ${app.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'This app will be removed from your device.',
          style: TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onUninstallApp(app.id);
            },
            child: const Text(
              'Uninstall',
              style: TextStyle(color: NunuColors.errorMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab({bool? filterGames}) {
    // Filter categories based on the current footer tab
    final gameCategories = [
      AppSubCategory.casual,
      AppSubCategory.puzzle,
      AppSubCategory.arcade,
      AppSubCategory.action,
      AppSubCategory.adventure,
      AppSubCategory.racing,
      AppSubCategory.sports,
      AppSubCategory.card,
      AppSubCategory.strategy,
    ];

    final appCategories = [
      AppSubCategory.tools,
      AppSubCategory.productivity,
      AppSubCategory.social,
      AppSubCategory.entertainment,
      AppSubCategory.education,
      AppSubCategory.health,
      AppSubCategory.finance,
      AppSubCategory.shopping,
      AppSubCategory.travel,
      AppSubCategory.weather,
      AppSubCategory.music,
    ];

    final categories = filterGames == true
        ? gameCategories
        : filterGames == false
        ? appCategories
        : AppSubCategory.values;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: () {
            // Show apps in this category
            final apps = getAppsBySubCategory(cat);
            if (apps.isNotEmpty) {
              setState(() => _selectedApp = apps.first);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                cat.name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppDetailPage(StoreApp app) {
    final isInstalled = widget.installedApps.contains(app.id);
    final needsUpdate = app.id == 'mega_merge' && !widget.megaMergeUpdated;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: NunuColors.backgroundPaper,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _selectedApp = null),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App header
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: app.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(app.icon, color: Colors.white, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                app.developer,
                                style: const TextStyle(
                                  color: NunuColors.primaryMain,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  app.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                            const Text(
                              'rating',
                              style: TextStyle(
                                color: NunuColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              app.downloads,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'downloads',
                              style: TextStyle(
                                color: NunuColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'E',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'everyone',
                              style: TextStyle(
                                color: NunuColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Install/Update button
                    SizedBox(
                      width: double.infinity,
                      child: _buildDetailInstallButton(
                        app,
                        isInstalled,
                        needsUpdate,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'about this app',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app.description ?? 'No description available.',
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        app.subCategory.name,
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 12,
                        ),
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

  Widget _buildDetailInstallButton(
    StoreApp app,
    bool isInstalled,
    bool needsUpdate,
  ) {
    if (needsUpdate) {
      return ElevatedButton(
        onPressed: () {
          widget.onUpdateApp(app);
          setState(() => _selectedApp = null);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: NunuColors.primaryMain,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'update',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isInstalled) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: NunuColors.textSecondary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'installed',
          style: TextStyle(color: NunuColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        widget.onInstallApp(app);
        setState(() => _selectedApp = null);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: NunuColors.successMain,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'install',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooterNav() {
    return Container(
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_footerTabs.length, (index) {
          final isSelected = _footerTabIndex == index;
          final tab = _footerTabs[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _footerTabIndex = index;
                if (index == 2) _isSearching = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.$1,
                    color: isSelected
                        ? NunuColors.primaryMain
                        : NunuColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      color: isSelected
                          ? NunuColors.primaryMain
                          : NunuColors.textSecondary,
                      fontSize: 11,
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
}
