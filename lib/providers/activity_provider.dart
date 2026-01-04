import 'package:flutter/material.dart';
import '../data/models/activity_model.dart';
import '../data/local/database_helper.dart';

class ActivityProvider extends ChangeNotifier {
  List<ActivityModel> _activities = [];
  List<ActivityModel> _filteredActivities = [];
  ActivityModel? _selectedActivity;
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filter
  String _searchQuery = '';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;

  // Database Helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Getters
  List<ActivityModel> get activities => _filteredActivities;
  ActivityModel? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _filteredActivities.isNotEmpty;

  // Set loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize - Load from SQLite
  Future<void> initialize() async {
    try {
      print('🔵 ActivityProvider: Initializing...');

      // Load dari database
      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('activities');

      if (maps.isEmpty) {
        // First time - insert mock data
        print('🟡 No data found, inserting mock data...');
        await _insertMockData();

        // Load again after insert
        final newMaps = await _dbHelper.queryAll('activities');
        _activities =
            newMaps.map((map) => ActivityModel.fromDatabase(map)).toList();
      } else {
        _activities =
            maps.map((map) => ActivityModel.fromDatabase(map)).toList();
      }

      _filteredActivities = List.from(_activities);
      print('✅ Loaded ${_activities.length} activities from SQLite');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing: $e');
      _setError('Failed to initialize: $e');
    }
  }

  /// Insert mock data (first time only)
  Future<void> _insertMockData() async {
    final mockActivities = _getMockActivities();

    for (var activity in mockActivities) {
      await _dbHelper.insert('activities', activity.toDatabase());
    }

    print('✅ Mock data inserted');
  }

  /// Fetch all activities
  Future<void> fetchActivities() async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('activities');
      _activities = maps.map((map) => ActivityModel.fromDatabase(map)).toList();
      _filteredActivities = List.from(_activities);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch activities by provider ID (untuk penyedia)
  Future<void> fetchMyActivities(int providerId) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('activities');

      // FILTER: hanya activity milik provider ini
      final filteredMaps =
          maps.where((map) => map['provider_id'] == providerId).toList();

      _activities =
          filteredMaps.map((map) => ActivityModel.fromDatabase(map)).toList();
      _filteredActivities = List.from(_activities);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch by ID
  Future<void> fetchActivityById(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 300));

      final map = await _dbHelper.queryById('activities', id);
      if (map != null) {
        _selectedActivity = ActivityModel.fromDatabase(map);
      } else {
        throw Exception('Kegiatan tidak ditemukan');
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Search
  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Filter by category
  void filterByCategory(String? categoryId) {
    _selectedCategory = categoryId;
    _applyFilters();
  }

  /// Filter by price
  void filterByPrice(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _minPrice = null;
    _maxPrice = null;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredActivities = _activities.where((activity) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            activity.name.toLowerCase().contains(_searchQuery) ||
                activity.location.toLowerCase().contains(_searchQuery) ||
                activity.description.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      // Category
      if (_selectedCategory != null) {
        if (activity.categoryId.toString() != _selectedCategory) return false;
      }

      // Price
      if (_minPrice != null && activity.price < _minPrice!) return false;
      if (_maxPrice != null && activity.price > _maxPrice!) return false;

      return true;
    }).toList();
  }

  /// Create activity
  Future<bool> createActivity(ActivityModel activity) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(seconds: 1));

      final newActivity = ActivityModel(
        id: DateTime.now().millisecondsSinceEpoch,
        providerId: activity.providerId,
        categoryId: activity.categoryId,
        name: activity.name,
        description: activity.description,
        location: activity.location,
        latitude: activity.latitude,
        longitude: activity.longitude,
        eventDate: activity.eventDate,
        registrationDeadline: activity.registrationDeadline,
        price: activity.price,
        capacity: activity.capacity,
        availableSlots: activity.availableSlots,
        images: activity.images,
        discountType: activity.discountType,
        discountValue: activity.discountValue,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to SQLite
      await _dbHelper.insert('activities', newActivity.toDatabase());
      await fetchActivities();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Update activity
  Future<bool> updateActivity(ActivityModel activity) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(seconds: 1));

      final updatedActivity = ActivityModel(
        id: activity.id,
        providerId: activity.providerId,
        categoryId: activity.categoryId,
        name: activity.name,
        description: activity.description,
        location: activity.location,
        latitude: activity.latitude,
        longitude: activity.longitude,
        eventDate: activity.eventDate,
        registrationDeadline: activity.registrationDeadline,
        price: activity.price,
        capacity: activity.capacity,
        availableSlots: activity.availableSlots,
        images: activity.images,
        discountType: activity.discountType,
        discountValue: activity.discountValue,
        isActive: activity.isActive,
        createdAt: activity.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update di SQLite
      await _dbHelper.update(
          'activities', updatedActivity.toDatabase(), activity.id);

      // Reload dari database
      await fetchActivities();

      if (_selectedActivity?.id == activity.id) {
        _selectedActivity = updatedActivity;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Delete activity
  Future<bool> deleteActivity(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      // Delete dari SQLite
      await _dbHelper.delete('activities', id);

      // Reload dari database
      await fetchActivities();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Mock data
  List<ActivityModel> _getMockActivities() {
    return [
      ActivityModel(
        id: 1,
        providerId: 1,
        categoryId: 1,
        name: 'Workshop Flutter Development',
        description:
            'Workshop intensif membuat aplikasi mobile dengan Flutter. Cocok untuk pemula hingga advanced.',
        location: 'Gedung IT Telkom University',
        latitude: -6.9147,
        longitude: 107.6098,
        eventDate: DateTime.now().add(const Duration(days: 7)),
        registrationDeadline: DateTime.now().add(const Duration(days: 5)),
        price: 150000,
        capacity: 50,
        availableSlots: 20,
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Workshop+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Workshop+2',
        ],
        discountType: 'percentage',
        discountValue: 20,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ActivityModel(
        id: 2,
        providerId: 1,
        categoryId: 2,
        name: 'Webinar AI & Machine Learning',
        description:
            'Webinar gratis tentang penerapan AI dan Machine Learning di industri. Pembicara dari Google.',
        location: 'Online - Zoom Meeting',
        eventDate: DateTime.now().add(const Duration(days: 3)),
        registrationDeadline: DateTime.now().add(const Duration(days: 2)),
        price: 0,
        capacity: 500,
        availableSlots: 150,
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Webinar+AI',
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      ActivityModel(
        id: 3,
        providerId: 1,
        categoryId: 3,
        name: 'Bootcamp Data Science',
        description:
            'Bootcamp intensif 3 bulan untuk menjadi Data Scientist profesional. Materi dari basic hingga advanced.',
        location: 'Kampus Bandung Technopark',
        latitude: -6.9175,
        longitude: 107.6191,
        eventDate: DateTime.now().add(const Duration(days: 30)),
        registrationDeadline: DateTime.now().add(const Duration(days: 20)),
        price: 5000000,
        capacity: 30,
        availableSlots: 10,
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Bootcamp+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Bootcamp+2',
        ],
        discountType: 'flat',
        discountValue: 500000,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
