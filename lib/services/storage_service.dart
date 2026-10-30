import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'studyhub_favorites';
  static const String _keyProgress = 'studyhub_watched_videos';
  static const String _keyTheme = 'studyhub_theme_mode';
  static const String _keyRememberedPassword = 'studyhub_saved_pw';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorites
  Set<String> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<void> saveFavorites(Set<String> favs) async {
    await _prefs.setStringList(_keyFavorites, favs.toList());
  }

  Future<void> toggleFavorite(String videoKey) async {
    final favs = getFavorites();
    if (favs.contains(videoKey)) {
      favs.remove(videoKey);
    } else {
      favs.add(videoKey);
    }
    await saveFavorites(favs);
  }

  // Progress tracking
  Set<String> getCompletedVideos() {
    final list = _prefs.getStringList(_keyProgress) ?? [];
    return list.toSet();
  }

  Future<void> saveCompletedVideos(Set<String> completed) async {
    await _prefs.setStringList(_keyProgress, completed.toList());
  }

  Future<void> toggleCompleted(String videoKey) async {
    final list = getCompletedVideos();
    if (list.contains(videoKey)) {
      list.remove(videoKey);
    } else {
      list.add(videoKey);
    }
    await saveCompletedVideos(list);
  }

  // Theme
  String getThemeMode() {
    return _prefs.getString(_keyTheme) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyTheme, mode);
  }

  // Remembered password
  String? getSavedPassword() {
    return _prefs.getString(_keyRememberedPassword);
  }

  Future<void> setSavedPassword(String? pw) async {
    if (pw == null || pw.isEmpty) {
      await _prefs.remove(_keyRememberedPassword);
    } else {
      await _prefs.setString(_keyRememberedPassword, pw);
    }
  }

  // Custom Admin-Managed Catalog
  static const String _keyCustomCatalog = 'studyhub_custom_catalog';
  String? getCustomCatalog() {
    return _prefs.getString(_keyCustomCatalog);
  }

  Future<void> saveCustomCatalog(String? jsonStr) async {
    if (jsonStr == null || jsonStr.isEmpty) {
      await _prefs.remove(_keyCustomCatalog);
    } else {
      await _prefs.setString(_keyCustomCatalog, jsonStr);
    }
  }

  // PDF Materials / Resources
  static const String _keyPdfResources = 'studyhub_pdf_resources';
  List<String> getPdfResourcesRaw() {
    return _prefs.getStringList(_keyPdfResources) ?? [];
  }

  Future<void> savePdfResourcesRaw(List<String> rawList) async {
    await _prefs.setStringList(_keyPdfResources, rawList);
  }

  // Admin PIN
  static const String _keyAdminPin = 'studyhub_admin_pin';
  String getAdminPin() {
    return _prefs.getString(_keyAdminPin) ?? '1234';
  }

  Future<void> setAdminPin(String pin) async {
    await _prefs.setString(_keyAdminPin, pin);
  }

  // Student Access Passcode (Short password, default 1234)
  static const String _keyAccessPassword = 'studyhub_access_password';
  String getAccessPassword() {
    return _prefs.getString(_keyAccessPassword) ?? '1234';
  }

  Future<void> setAccessPassword(String password) async {
    await _prefs.setString(_keyAccessPassword, password);
  }
}

