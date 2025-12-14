import 'package:flutter/material.dart';

/// Holds all the state for the settings mini-app
class SettingsAppState {
  // Profile settings
  String userName;
  String userEmail;
  String userPhone;
  String userBio;
  int profilePhotoIndex;
  
  // Account settings
  bool twoFactorEnabled;
  int activeSessions;
  
  // Notification settings
  bool pushNotifications;
  bool emailNotifications;
  bool marketingEmails;
  bool notificationSound;
  bool notificationVibration;
  TimeOfDay quietHoursStart;
  TimeOfDay quietHoursEnd;
  bool quietHoursEnabled;
  
  // Privacy settings
  bool locationSharing;
  bool analyticsEnabled;
  bool personalizedAds;
  String profileVisibility;
  
  // Display settings
  bool darkMode;
  double fontSize;
  bool animationsEnabled;
  bool compactMode;
  bool reducedMotion;
  
  // Sound settings
  double masterVolume;
  String notificationTone;
  bool hapticFeedback;
  bool keyboardSounds;
  bool inAppSounds;
  
  // Language & Region
  String language;
  String region;
  String dateFormat;
  bool use24HourTime;
  String timezone;
  
  // Data & Storage
  bool autoDownload;
  String downloadQuality;
  String cacheSize;
  bool saveToGallery;
  bool wifiOnlyDownload;
  
  // Linked accounts
  bool googleLinked;
  bool appleLinked;
  bool facebookLinked;
  bool twitterLinked;
  
  // Accessibility
  bool screenReaderOptimized;
  bool highContrast;
  bool largeText;
  bool boldText;
  
  // App info
  final String appVersion;
  final String buildNumber;
  
  SettingsAppState({
    this.userName = 'William Bernard',
    this.userEmail = 'william.bernard@email.com',
    this.userPhone = '+1 (555) 123-4567',
    this.userBio = 'Software developer & coffee enthusiast ☕',
    this.profilePhotoIndex = 0,
    this.twoFactorEnabled = false,
    this.activeSessions = 3,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.marketingEmails = false,
    this.notificationSound = true,
    this.notificationVibration = true,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.quietHoursEnabled = false,
    this.locationSharing = false,
    this.analyticsEnabled = true,
    this.personalizedAds = true,
    this.profileVisibility = 'Friends',
    this.darkMode = true,
    this.fontSize = 1.0,
    this.animationsEnabled = true,
    this.compactMode = false,
    this.reducedMotion = false,
    this.masterVolume = 0.8,
    this.notificationTone = 'Chime',
    this.hapticFeedback = true,
    this.keyboardSounds = false,
    this.inAppSounds = true,
    this.language = 'English',
    this.region = 'United States',
    this.dateFormat = 'MM/DD/YYYY',
    this.use24HourTime = false,
    this.timezone = 'Pacific Time (PT)',
    this.autoDownload = true,
    this.downloadQuality = 'High',
    this.cacheSize = '234 MB',
    this.saveToGallery = true,
    this.wifiOnlyDownload = true,
    this.googleLinked = true,
    this.appleLinked = false,
    this.facebookLinked = false,
    this.twitterLinked = true,
    this.screenReaderOptimized = false,
    this.highContrast = false,
    this.largeText = false,
    this.boldText = false,
    this.appVersion = '2.4.1',
    this.buildNumber = '2024120801',
  });
  
  /// Profile photo options (emoji-based for simplicity)
  static const List<String> profilePhotos = [
    '👤', // default
    '🧑‍💻', // developer
    '👨‍🔬', // scientist
    '👩‍🎨', // artist
    '🧑‍🚀', // astronaut
    '👨‍🍳', // chef
    '👩‍⚕️', // doctor
    '🧑‍🎤', // musician
    '👨‍✈️', // pilot
    '👩‍🏫', // teacher
    '🦸', // superhero
    '🥷', // ninja
  ];
  
  String get currentProfilePhoto => profilePhotos[profilePhotoIndex];
  
  /// Available languages
  static const List<String> availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Dutch',
    'Russian',
    'Japanese',
    'Chinese',
    'Korean',
    'Arabic',
    'Hindi',
    'Turkish',
    'Polish',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Greek',
    'Hebrew',
    'Thai',
    'Vietnamese',
    'Indonesian',
    'Malay',
    'Filipino',
    'Czech',
    'Hungarian',
    'Romanian',
    'Ukrainian',
  ];
  
  /// Available regions
  static const List<String> availableRegions = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Japan',
    'China',
    'India',
    'Brazil',
    'Mexico',
  ];
  
  /// Available timezones
  static const List<String> availableTimezones = [
    'Pacific Time (PT)',
    'Mountain Time (MT)',
    'Central Time (CT)',
    'Eastern Time (ET)',
    'UTC',
    'Central European Time (CET)',
    'Eastern European Time (EET)',
    'Japan Standard Time (JST)',
    'China Standard Time (CST)',
    'India Standard Time (IST)',
    'Australian Eastern Time (AET)',
  ];
  
  /// Notification tones
  static const List<String> notificationTones = [
    'Chime',
    'Bell',
    'Ping',
    'Pop',
    'Swoosh',
    'Ding',
    'Bubble',
    'Crystal',
  ];
  
  /// Date formats
  static const List<String> dateFormats = [
    'MM/DD/YYYY',
    'DD/MM/YYYY',
    'YYYY-MM-DD',
    'DD.MM.YYYY',
  ];
  
  /// Download qualities
  static const List<String> downloadQualities = [
    'Low',
    'Medium',
    'High',
    'Original',
  ];
  
  /// Profile visibility options
  static const List<String> visibilityOptions = [
    'Public',
    'Friends',
    'Private',
  ];
}

