import 'package:flutter/material.dart';
import '../data/models/bookmark_model.dart';
import '../data/models/residence_model.dart';
import '../data/models/activity_model.dart';
import '../data/models/marketplace_product_model.dart';
import '../data/local/database_helper.dart';

class BookmarkProvider extends ChangeNotifier {
  List<BookmarkModel> _bookmarks = [];
  List<ResidenceModel> _bookmarkedResidences = [];
  List<ActivityModel> _bookmarkedActivities = [];
  List<MarketplaceProductModel> _bookmarkedProducts = [];

  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Getters
  List<BookmarkModel> get bookmarks => _bookmarks;
  List<ResidenceModel> get bookmarkedResidences => _bookmarkedResidences;
  List<ActivityModel> get bookmarkedActivities => _bookmarkedActivities;
  List<MarketplaceProductModel> get bookmarkedProducts => _bookmarkedProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Load bookmarks untuk user
  Future<void> loadBookmarks(int userId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Query bookmarks dari database
      final maps = await _dbHelper.queryWhere(
        'bookmarks',
        'user_id = ?',
        [userId],
      );

      _bookmarks = maps.map((map) => BookmarkModel.fromDatabase(map)).toList();

      // Load full data untuk setiap bookmark
      await _loadBookmarkedItems();

      _setLoading(false);
      print('✅ Loaded ${_bookmarks.length} bookmarks');
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error loading bookmarks: $e');
    }
  }

  /// Load full data dari residence/activity/marketplace
  Future<void> _loadBookmarkedItems() async {
    _bookmarkedResidences.clear();
    _bookmarkedActivities.clear();
    _bookmarkedProducts.clear();

    for (var bookmark in _bookmarks) {
      if (bookmark.bookmarkableType == 'residence') {
        final map =
            await _dbHelper.queryById('residences', bookmark.bookmarkableId);
        if (map != null) {
          _bookmarkedResidences.add(ResidenceModel.fromDatabase(map));
        }
      } else if (bookmark.bookmarkableType == 'activity') {
        final map =
            await _dbHelper.queryById('activities', bookmark.bookmarkableId);
        if (map != null) {
          _bookmarkedActivities.add(ActivityModel.fromDatabase(map));
        }
      } else if (bookmark.bookmarkableType == 'marketplace') {
        final map =
            await _dbHelper.queryById('marketplace', bookmark.bookmarkableId);
        if (map != null) {
          _bookmarkedProducts.add(MarketplaceProductModel.fromDatabase(map));
        }
      }
    }
  }

  /// Check apakah item sudah di-bookmark
  bool isBookmarked(String type, int itemId, int userId) {
    return _bookmarks.any((b) =>
        b.userId == userId &&
        b.bookmarkableType == type &&
        b.bookmarkableId == itemId);
  }

  /// Toggle bookmark (add/remove)
  Future<bool> toggleBookmark({
    required int userId,
    required String type, // 'residence', 'activity', 'marketplace'
    required int itemId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final isCurrentlyBookmarked = isBookmarked(type, itemId, userId);

      if (isCurrentlyBookmarked) {
        // Remove bookmark
        final bookmark = _bookmarks.firstWhere((b) =>
            b.userId == userId &&
            b.bookmarkableType == type &&
            b.bookmarkableId == itemId);

        await _dbHelper.delete('bookmarks', bookmark.id);
        print('✅ Bookmark removed');
      } else {
        // Add bookmark
        final bookmarkData = {
          'user_id': userId,
          'bookmarkable_type': type,
          'bookmarkable_id': itemId,
          'created_at': DateTime.now().toIso8601String(),
        };

        final id = await _dbHelper.insert('bookmarks', bookmarkData);
        print('✅ Bookmark added with ID: $id');
      }

      // Reload bookmarks
      await loadBookmarks(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error toggling bookmark: $e');
      return false;
    }
  }

  /// Clear bookmarks (saat logout)
  void clearBookmarks() {
    _bookmarks.clear();
    _bookmarkedResidences.clear();
    _bookmarkedActivities.clear();
    _bookmarkedProducts.clear();
    notifyListeners();
  }
}
