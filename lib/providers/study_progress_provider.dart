import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';

class StudyProgressProvider extends ChangeNotifier {
  final StorageService _storage;
  Set<String> _favorites = {};
  Set<String> _completed = {};

  StudyProgressProvider(this._storage) {
    _loadData();
  }

  Set<String> get favorites => _favorites;
  Set<String> get completed => _completed;

  int get totalFavoritesCount => _favorites.length;
  int get totalCompletedCount => _completed.length;

  void _loadData() {
    _favorites = _storage.getFavorites();
    _completed = _storage.getCompletedVideos();
    notifyListeners();
  }

  bool isFavorite(String key) => _favorites.contains(key);
  bool isCompleted(String key) => _completed.contains(key);

  void toggleFavorite(String key) {
    if (_favorites.contains(key)) {
      _favorites.remove(key);
    } else {
      _favorites.add(key);
    }
    _storage.saveFavorites(_favorites);
    notifyListeners();
  }

  void toggleCompleted(String key) {
    if (_completed.contains(key)) {
      _completed.remove(key);
    } else {
      _completed.add(key);
    }
    _storage.saveCompletedVideos(_completed);
    notifyListeners();
  }

  double getSubjectProgress(CourseSubject subject) {
    int total = subject.totalVideos;
    if (total == 0) return 0.0;
    int done = getSubjectCompletedCount(subject);
    return (done / total).clamp(0.0, 1.0);
  }

  int getSubjectCompletedCount(CourseSubject subject) {
    int count = 0;
    for (final unit in subject.units) {
      for (final video in unit.videos) {
        if (_completed.contains(video.key)) {
          count++;
        }
      }
    }
    return count;
  }
}
