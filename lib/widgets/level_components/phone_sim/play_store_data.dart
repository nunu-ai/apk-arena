import 'package:flutter/material.dart';

enum AppCategory {
  games,
  apps,
  kids,
}

enum AppSubCategory {
  casual,
  puzzle,
  arcade,
  action,
  adventure,
  racing,
  sports,
  card,
  strategy,
  tools,
  productivity,
  social,
  entertainment,
  education,
  health,
  finance,
  shopping,
  travel,
  weather,
  music,
}

class StoreApp {
  final String id;
  final String name;
  final String developer;
  final IconData icon;
  final Color color;
  final double rating;
  final String downloads;
  final AppCategory category;
  final AppSubCategory subCategory;
  final bool isSpecialApp; // Place the Cards or Mega Merge
  final bool requiresUpdate;
  final String? description;

  const StoreApp({
    required this.id,
    required this.name,
    required this.developer,
    required this.icon,
    required this.color,
    required this.rating,
    required this.downloads,
    required this.category,
    required this.subCategory,
    this.isSpecialApp = false,
    this.requiresUpdate = false,
    this.description,
  });
}

/// The two special apps that are playable
const StoreApp placeTheCardsApp = StoreApp(
  id: 'place_the_cards',
  name: 'Place the Cards',
  developer: 'CardMaster Games',
  icon: Icons.style,
  color: Color(0xFF3B7DD8),
  rating: 4.2,
  downloads: '500K+',
  category: AppCategory.games,
  subCategory: AppSubCategory.card,
  isSpecialApp: true,
  description: 'A relaxing card sorting puzzle game. Match cards by category and clear the board!',
);

const StoreApp megaMergeApp = StoreApp(
  id: 'mega_merge',
  name: 'Mega Merge',
  developer: 'MergeCorp Studios',
  icon: Icons.merge_type,
  color: Color(0xFF9C27B0),
  rating: 4.5,
  downloads: '1M+',
  category: AppCategory.games,
  subCategory: AppSubCategory.puzzle,
  isSpecialApp: true,
  requiresUpdate: true,
  description: 'Merge items to create powerful combinations! Build your factory empire.',
);

/// Generate 100 fake apps for the store
List<StoreApp> generateStoreApps() {
  final List<StoreApp> apps = [];

  // Add the two special apps first
  apps.add(placeTheCardsApp);
  apps.add(megaMergeApp);

  // Game apps (50)
  final gameApps = [
    ('Pixel Warriors', Icons.sports_esports, Color(0xFFE53935), 'Pixel Studios', AppSubCategory.action, '10M+', 4.3),
    ('Bubble Pop Mania', Icons.bubble_chart, Color(0xFFFF9800), 'PopGames', AppSubCategory.casual, '5M+', 4.1),
    ('Speed Racer X', Icons.directions_car, Color(0xFF2196F3), 'Racing Inc', AppSubCategory.racing, '2M+', 4.4),
    ('Chess Master Pro', Icons.grid_on, Color(0xFF795548), 'BoardGame Labs', AppSubCategory.strategy, '1M+', 4.7),
    ('Zombie Survival', Icons.coronavirus, Color(0xFF4CAF50), 'Undead Games', AppSubCategory.action, '8M+', 4.0),
    ('Candy Crush Clone', Icons.cake, Color(0xFFE91E63), 'Sweet Studios', AppSubCategory.puzzle, '50M+', 4.2),
    ('Farm Heroes', Icons.agriculture, Color(0xFF8BC34A), 'FarmVille Inc', AppSubCategory.casual, '20M+', 4.3),
    ('Space Invaders 2', Icons.rocket, Color(0xFF3F51B5), 'Retro Games', AppSubCategory.arcade, '3M+', 4.5),
    ('Angry Cats', Icons.pets, Color(0xFFFF5722), 'Pet Games', AppSubCategory.casual, '15M+', 4.1),
    ('Word Puzzle Pro', Icons.abc, Color(0xFF009688), 'Word Labs', AppSubCategory.puzzle, '7M+', 4.6),
    ('Soccer Star 2024', Icons.sports_soccer, Color(0xFF4CAF50), 'Sports Games', AppSubCategory.sports, '25M+', 4.4),
    ('Ninja Runner', Icons.run_circle, Color(0xFF212121), 'Ninja Inc', AppSubCategory.action, '4M+', 4.2),
    ('Tower Defense X', Icons.castle, Color(0xFF673AB7), 'Defense Games', AppSubCategory.strategy, '2M+', 4.3),
    ('Fishing Paradise', Icons.phishing, Color(0xFF00BCD4), 'Ocean Games', AppSubCategory.casual, '1M+', 4.0),
    ('Golf Champion', Icons.golf_course, Color(0xFF4CAF50), 'Golf Studios', AppSubCategory.sports, '500K+', 4.5),
    ('Dungeon Crawler', Icons.explore, Color(0xFF5D4037), 'RPG Games', AppSubCategory.adventure, '3M+', 4.4),
    ('Poker Night', Icons.casino, Color(0xFFC62828), 'Casino Games', AppSubCategory.card, '6M+', 4.1),
    ('Tetris Classic', Icons.view_module, Color(0xFF1976D2), 'Classic Games', AppSubCategory.arcade, '10M+', 4.7),
    ('Fruit Slice', Icons.local_dining, Color(0xFFFF9800), 'Slice Studios', AppSubCategory.arcade, '8M+', 4.0),
    ('Sniper Elite', Icons.gps_fixed, Color(0xFF455A64), 'Shooter Inc', AppSubCategory.action, '5M+', 4.3),
    ('Cooking Mama', Icons.restaurant, Color(0xFFF44336), 'Cooking Games', AppSubCategory.casual, '12M+', 4.2),
    ('Basketball Stars', Icons.sports_basketball, Color(0xFFFF5722), 'Sports Inc', AppSubCategory.sports, '4M+', 4.4),
    ('Puzzle Quest', Icons.extension, Color(0xFF9C27B0), 'Quest Games', AppSubCategory.puzzle, '2M+', 4.5),
    ('Racing Rivals', Icons.speed, Color(0xFFF44336), 'Race Studios', AppSubCategory.racing, '7M+', 4.3),
    ('Pet Simulator', Icons.cruelty_free, Color(0xFFFFEB3B), 'Pet World', AppSubCategory.casual, '3M+', 4.1),
    ('Block Builder', Icons.view_in_ar, Color(0xFF795548), 'Build Games', AppSubCategory.casual, '15M+', 4.6),
    ('Trivia King', Icons.quiz, Color(0xFF00BCD4), 'Quiz Games', AppSubCategory.puzzle, '2M+', 4.2),
    ('Solitaire Free', Icons.grid_view, Color(0xFF2E7D32), 'Card Masters', AppSubCategory.card, '20M+', 4.4),
    ('Tennis Pro', Icons.sports_tennis, Color(0xFFCDDC39), 'Tennis Inc', AppSubCategory.sports, '1M+', 4.3),
    ('Mahjong Master', Icons.interests, Color(0xFF8D6E63), 'Board Games', AppSubCategory.puzzle, '5M+', 4.5),
    ('Crossword Daily', Icons.border_all, Color(0xFF607D8B), 'Word Games', AppSubCategory.puzzle, '3M+', 4.4),
    ('Slot Machine', Icons.casino, Color(0xFFFFD700), 'Vegas Games', AppSubCategory.casual, '4M+', 3.9),
    ('Mini Golf 3D', Icons.golf_course, Color(0xFF66BB6A), 'Mini Games', AppSubCategory.sports, '2M+', 4.2),
    ('Pinball Wizard', Icons.sports_baseball, Color(0xFF7B1FA2), 'Arcade Inc', AppSubCategory.arcade, '1M+', 4.3),
    ('Match 3 Gems', Icons.diamond, Color(0xFFE040FB), 'Gem Studios', AppSubCategory.puzzle, '6M+', 4.1),
    ('Darts Champion', Icons.gps_fixed, Color(0xFFF44336), 'Darts Inc', AppSubCategory.sports, '500K+', 4.0),
    ('Bike Race', Icons.pedal_bike, Color(0xFFFF9800), 'Bike Games', AppSubCategory.racing, '8M+', 4.4),
    ('Word Search', Icons.search, Color(0xFF00ACC1), 'Search Games', AppSubCategory.puzzle, '4M+', 4.3),
    ('Checkers Pro', Icons.dashboard, Color(0xFFD84315), 'Board Pro', AppSubCategory.strategy, '2M+', 4.5),
    ('Bowling King', Icons.sports, Color(0xFF1565C0), 'Bowling Inc', AppSubCategory.sports, '3M+', 4.2),
    ('Jigsaw Puzzles', Icons.widgets, Color(0xFF8E24AA), 'Jigsaw Inc', AppSubCategory.puzzle, '5M+', 4.6),
    ('Backgammon', Icons.grid_4x4, Color(0xFF5D4037), 'Ancient Games', AppSubCategory.strategy, '1M+', 4.4),
    ('Archery Master', Icons.architecture, Color(0xFF388E3C), 'Archery Inc', AppSubCategory.sports, '2M+', 4.1),
    ('Snake Classic', Icons.linear_scale, Color(0xFF4CAF50), 'Retro Inc', AppSubCategory.arcade, '10M+', 4.3),
    ('Pool Billiards', Icons.circle, Color(0xFF1B5E20), 'Pool Games', AppSubCategory.sports, '4M+', 4.2),
    ('Memory Match', Icons.psychology, Color(0xFF9575CD), 'Mind Games', AppSubCategory.puzzle, '3M+', 4.5),
    ('Dominos', Icons.filter_none, Color(0xFF212121), 'Domino Inc', AppSubCategory.strategy, '1M+', 4.3),
    ('UNO Friends', Icons.color_lens, Color(0xFFF44336), 'Card Fun', AppSubCategory.card, '7M+', 4.4),
  ];

  // Utility/Tool apps (30)
  final toolApps = [
    ('Calculator Pro', Icons.calculate, Color(0xFF607D8B), 'Tools Inc', AppSubCategory.tools, '10M+', 4.5),
    ('Weather Today', Icons.cloud, Color(0xFF03A9F4), 'Weather Co', AppSubCategory.weather, '5M+', 4.2),
    ('Flashlight Ultra', Icons.flashlight_on, Color(0xFFFFEB3B), 'Light Apps', AppSubCategory.tools, '50M+', 4.0),
    ('QR Scanner', Icons.qr_code_scanner, Color(0xFF424242), 'Scan Inc', AppSubCategory.tools, '20M+', 4.3),
    ('Notes Plus', Icons.note_alt, Color(0xFFFFC107), 'Note Apps', AppSubCategory.productivity, '8M+', 4.4),
    ('File Manager', Icons.folder, Color(0xFF2196F3), 'File Inc', AppSubCategory.tools, '15M+', 4.2),
    ('PDF Reader', Icons.picture_as_pdf, Color(0xFFF44336), 'Doc Apps', AppSubCategory.productivity, '10M+', 4.1),
    ('Alarm Clock', Icons.alarm, Color(0xFF9C27B0), 'Time Apps', AppSubCategory.tools, '5M+', 4.3),
    ('Compass', Icons.explore, Color(0xFF4CAF50), 'Navigate Inc', AppSubCategory.tools, '3M+', 4.0),
    ('Unit Converter', Icons.swap_horiz, Color(0xFF00BCD4), 'Convert Co', AppSubCategory.tools, '2M+', 4.4),
    ('Voice Recorder', Icons.mic, Color(0xFFE91E63), 'Audio Inc', AppSubCategory.tools, '7M+', 4.2),
    ('Tip Calculator', Icons.attach_money, Color(0xFF4CAF50), 'Money Apps', AppSubCategory.finance, '1M+', 4.5),
    ('To-Do List', Icons.checklist, Color(0xFF3F51B5), 'Task Inc', AppSubCategory.productivity, '6M+', 4.3),
    ('Meditation', Icons.self_improvement, Color(0xFF26A69A), 'Calm Inc', AppSubCategory.health, '4M+', 4.6),
    ('Step Counter', Icons.directions_walk, Color(0xFFFF5722), 'Fitness Co', AppSubCategory.health, '8M+', 4.1),
    ('Password Safe', Icons.lock, Color(0xFF455A64), 'Security Inc', AppSubCategory.tools, '2M+', 4.4),
    ('Screen Recorder', Icons.screen_share, Color(0xFF7C4DFF), 'Record Inc', AppSubCategory.tools, '5M+', 4.0),
    ('Photo Editor', Icons.photo_camera, Color(0xFFE91E63), 'Photo Inc', AppSubCategory.tools, '12M+', 4.3),
    ('Music Player', Icons.music_note, Color(0xFFFF9800), 'Audio Apps', AppSubCategory.music, '10M+', 4.2),
    ('Video Player', Icons.video_library, Color(0xFF673AB7), 'Video Inc', AppSubCategory.entertainment, '7M+', 4.4),
  ];

  // Social/Entertainment apps (18)
  final socialApps = [
    ('Chat Messenger', Icons.chat, Color(0xFF2196F3), 'Chat Inc', AppSubCategory.social, '100M+', 4.5),
    ('Video Call', Icons.video_call, Color(0xFF4CAF50), 'Call Inc', AppSubCategory.social, '50M+', 4.3),
    ('Photo Share', Icons.photo, Color(0xFFE91E63), 'Share Inc', AppSubCategory.social, '30M+', 4.2),
    ('News Feed', Icons.newspaper, Color(0xFF607D8B), 'News Inc', AppSubCategory.entertainment, '20M+', 4.0),
    ('Podcast App', Icons.podcasts, Color(0xFF9C27B0), 'Podcast Co', AppSubCategory.entertainment, '10M+', 4.4),
    ('Streaming TV', Icons.tv, Color(0xFFF44336), 'Stream Inc', AppSubCategory.entertainment, '50M+', 4.5),
    ('Social Network', Icons.people, Color(0xFF1976D2), 'Social Co', AppSubCategory.social, '80M+', 4.1),
    ('Dating App', Icons.favorite, Color(0xFFE91E63), 'Love Inc', AppSubCategory.social, '15M+', 3.9),
    ('Recipe Book', Icons.menu_book, Color(0xFFFF5722), 'Recipe Co', AppSubCategory.entertainment, '5M+', 4.3),
    ('Wallpapers HD', Icons.wallpaper, Color(0xFF00BCD4), 'Wall Inc', AppSubCategory.entertainment, '10M+', 4.2),
    ('Meme Maker', Icons.sentiment_very_satisfied, Color(0xFFFFEB3B), 'Meme Inc', AppSubCategory.entertainment, '3M+', 4.0),
    ('Book Reader', Icons.book, Color(0xFF795548), 'Book Co', AppSubCategory.entertainment, '8M+', 4.6),
    ('Language Learn', Icons.translate, Color(0xFF4CAF50), 'Learn Inc', AppSubCategory.education, '15M+', 4.5),
    ('Math Tutor', Icons.functions, Color(0xFF3F51B5), 'Edu Inc', AppSubCategory.education, '5M+', 4.4),
    ('Kids ABC', Icons.child_care, Color(0xFFFF9800), 'Kids Inc', AppSubCategory.education, '10M+', 4.3),
    ('Budget Tracker', Icons.account_balance_wallet, Color(0xFF4CAF50), 'Finance Co', AppSubCategory.finance, '3M+', 4.2),
    ('Stock Market', Icons.trending_up, Color(0xFF00C853), 'Invest Inc', AppSubCategory.finance, '2M+', 4.1),
    ('Travel Planner', Icons.flight, Color(0xFF03A9F4), 'Travel Co', AppSubCategory.travel, '4M+', 4.3),
  ];

  int idCounter = 1;

  for (final app in gameApps) {
    apps.add(StoreApp(
      id: 'game_$idCounter',
      name: app.$1,
      developer: app.$4,
      icon: app.$2,
      color: app.$3,
      rating: app.$7,
      downloads: app.$6,
      category: AppCategory.games,
      subCategory: app.$5,
    ));
    idCounter++;
  }

  for (final app in toolApps) {
    apps.add(StoreApp(
      id: 'tool_$idCounter',
      name: app.$1,
      developer: app.$4,
      icon: app.$2,
      color: app.$3,
      rating: app.$7,
      downloads: app.$6,
      category: AppCategory.apps,
      subCategory: app.$5,
    ));
    idCounter++;
  }

  for (final app in socialApps) {
    apps.add(StoreApp(
      id: 'social_$idCounter',
      name: app.$1,
      developer: app.$4,
      icon: app.$2,
      color: app.$3,
      rating: app.$7,
      downloads: app.$6,
      category: AppCategory.apps,
      subCategory: app.$5,
    ));
    idCounter++;
  }

  return apps;
}

/// Get all store apps
final List<StoreApp> allStoreApps = generateStoreApps();

/// Filter apps by category
List<StoreApp> getAppsByCategory(AppCategory category) {
  return allStoreApps.where((app) => app.category == category).toList();
}

/// Filter apps by subcategory
List<StoreApp> getAppsBySubCategory(AppSubCategory subCategory) {
  return allStoreApps.where((app) => app.subCategory == subCategory).toList();
}

/// Get top rated apps
List<StoreApp> getTopRatedApps({int limit = 20}) {
  final sorted = List<StoreApp>.from(allStoreApps)
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted.take(limit).toList();
}

/// Get featured apps for "For you" section
List<StoreApp> getFeaturedApps() {
  // Return special apps + some high-rated ones
  final featured = <StoreApp>[placeTheCardsApp, megaMergeApp];
  featured.addAll(getTopRatedApps(limit: 8).where((a) => !a.isSpecialApp));
  return featured;
}

/// Get kids-friendly apps
List<StoreApp> getKidsApps() {
  return allStoreApps.where((app) => 
    app.subCategory == AppSubCategory.education ||
    app.subCategory == AppSubCategory.casual ||
    app.name.toLowerCase().contains('kids')
  ).toList();
}

