import 'package:flutter/material.dart';
import '../data/models/residence_model.dart';
import '../data/local/database_helper.dart';

class ResidenceProvider extends ChangeNotifier {
  List<ResidenceModel> _residences = [];
  List<ResidenceModel> _filteredResidences = [];
  ResidenceModel? _selectedResidence;
  bool _isLoading = false;
  String? _errorMessage;

  // Database Helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Search & Filter
  String _searchQuery = '';
  String? _selectedCategory;
  String? _rentalPeriod;
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<ResidenceModel> get residences => _filteredResidences;
  ResidenceModel? get selectedResidence => _selectedResidence;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _filteredResidences.isNotEmpty;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize - Load from SQLite
  Future<void> initialize() async {
    try {
      print('🔵 ResidenceProvider: Initializing...');

      // Load dari database
      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('residences');

      if (maps.isEmpty) {
        // First time - insert mock data
        print('🟡 No data found, inserting mock data...');
        await _insertMockData();

        // Load again after insert
        final newMaps = await _dbHelper.queryAll('residences');
        _residences =
            newMaps.map((map) => ResidenceModel.fromDatabase(map)).toList();
      } else {
        _residences =
            maps.map((map) => ResidenceModel.fromDatabase(map)).toList();
      }

      _filteredResidences = List.from(_residences);
      print('✅ Loaded ${_residences.length} residences from SQLite');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing: $e');
      _setError('Failed to initialize: $e');
    }
  }

  /// Insert mock data (first time only)
  Future<void> _insertMockData() async {
    final mockResidences = _getMockResidences();

    for (var residence in mockResidences) {
      await _dbHelper.insert('residences', residence.toDatabase());
    }

    print('✅ Mock data inserted');
  }

  /// Fetch all residences
  Future<void> fetchResidences() async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('residences');
      _residences =
          maps.map((map) => ResidenceModel.fromDatabase(map)).toList();
      _filteredResidences = List.from(_residences);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch residences by provider ID (untuk penyedia)
  Future<void> fetchMyResidences(int providerId) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('residences');

      // FILTER: hanya residence milik provider ini
      final filteredMaps =
          maps.where((map) => map['provider_id'] == providerId).toList();

      _residences =
          filteredMaps.map((map) => ResidenceModel.fromDatabase(map)).toList();
      _filteredResidences = List.from(_residences);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch by ID
  Future<void> fetchResidenceById(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 300));

      final map = await _dbHelper.queryById('residences', id);
      if (map != null) {
        _selectedResidence = ResidenceModel.fromDatabase(map);
      } else {
        throw Exception('Hunian tidak ditemukan');
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

  /// Filter by rental period
  void filterByRentalPeriod(String? period) {
    _rentalPeriod = period;
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
    _rentalPeriod = null;
    _minPrice = null;
    _maxPrice = null;
    _applyFilters();
  }

  /// Apply filters
  void _applyFilters() {
    _filteredResidences = _residences.where((residence) {
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            residence.name.toLowerCase().contains(_searchQuery) ||
                residence.address.toLowerCase().contains(_searchQuery) ||
                residence.description.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      if (_selectedCategory != null) {
        if (residence.categoryId.toString() != _selectedCategory) return false;
      }

      if (_rentalPeriod != null) {
        if (residence.rentalPeriod != _rentalPeriod) return false;
      }

      if (_minPrice != null && residence.price < _minPrice!) return false;
      if (_maxPrice != null && residence.price > _maxPrice!) return false;

      return true;
    }).toList();

    notifyListeners();
  }

  /// CREATE
  Future<bool> createResidence(ResidenceModel residence) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final newResidence = ResidenceModel(
        id: DateTime.now().millisecondsSinceEpoch,
        providerId: residence.providerId,
        categoryId: residence.categoryId,
        name: residence.name,
        description: residence.description,
        address: residence.address,
        latitude: residence.latitude,
        longitude: residence.longitude,
        rentalPeriod: residence.rentalPeriod,
        price: residence.price,
        capacity: residence.capacity,
        availableSlots: residence.availableSlots,
        facilities: residence.facilities,
        images: residence.images,
        discountType: residence.discountType,
        discountValue: residence.discountValue,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert ke SQLite
      await _dbHelper.insert('residences', newResidence.toDatabase());

      // Reload dari database
      await fetchResidences();

      _setLoading(false);
      print('✅ Residence created successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error creating residence: $e');
      return false;
    }
  }

  /// UPDATE
  Future<bool> updateResidence(ResidenceModel residence) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final updatedResidence = ResidenceModel(
        id: residence.id,
        providerId: residence.providerId,
        categoryId: residence.categoryId,
        name: residence.name,
        description: residence.description,
        address: residence.address,
        latitude: residence.latitude,
        longitude: residence.longitude,
        rentalPeriod: residence.rentalPeriod,
        price: residence.price,
        capacity: residence.capacity,
        availableSlots: residence.availableSlots,
        facilities: residence.facilities,
        images: residence.images,
        discountType: residence.discountType,
        discountValue: residence.discountValue,
        isActive: residence.isActive,
        createdAt: residence.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update di SQLite
      await _dbHelper.update(
          'residences', updatedResidence.toDatabase(), residence.id);

      // Reload dari database
      await fetchResidences();

      if (_selectedResidence?.id == residence.id) {
        _selectedResidence = updatedResidence;
      }

      _setLoading(false);
      print('✅ Residence updated successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error updating residence: $e');
      return false;
    }
  }

  /// DELETE
  Future<bool> deleteResidence(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      // Delete dari SQLite
      await _dbHelper.delete('residences', id);

      // Reload dari database
      await fetchResidences();

      _setLoading(false);
      print('✅ Residence deleted successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error deleting residence: $e');
      return false;
    }
  }

  /// Mock data
  List<ResidenceModel> _getMockResidences() {
    return [
      ResidenceModel(
        id: 1,
        providerId: 1,
        categoryId: 1,
        name: 'Kos Putri Sukabirus Premium',
        description:
            'Kos nyaman dan strategis dekat kampus. Fasilitas lengkap dengan keamanan 24 jam.',
        address: 'Jl. Sukabirus No. 45, Bandung',
        latitude: -6.9147,
        longitude: 107.6098,
        rentalPeriod: 'monthly',
        price: 1500000,
        capacity: 20,
        availableSlots: 5,
        facilities: ['WiFi', 'Kasur', 'Lemari', 'AC', 'Kamar Mandi Dalam'],
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Kos+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Kos+2',
        ],
        discountType: 'percentage',
        discountValue: 10,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      ResidenceModel(
        id: 2,
        providerId: 1,
        categoryId: 1,
        name: 'Apartemen Dago View',
        description:
            'Apartemen mewah dengan pemandangan kota. Lokasi strategis di pusat kota.',
        address: 'Jl. Ir. H. Djuanda No. 123, Bandung',
        latitude: -6.8700,
        longitude: 107.6100,
        rentalPeriod: 'yearly',
        price: 35000000,
        capacity: 1,
        availableSlots: 1,
        facilities: [
          'WiFi',
          'Fully Furnished',
          'Swimming Pool',
          'Gym',
          'Parkir'
        ],
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Apt+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Apt+2',
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      ResidenceModel(
        id: 3,
        providerId: 1,
        categoryId: 2,
        name: 'Kontrakan Keluarga Cisitu',
        description:
            'Rumah kontrakan cocok untuk keluarga. Lingkungan tenang dan nyaman.',
        address: 'Jl. Cisitu Lama No. 78, Bandung',
        latitude: -6.8800,
        longitude: 107.6200,
        rentalPeriod: 'yearly',
        price: 25000000,
        capacity: 5,
        availableSlots: 1,
        facilities: [
          '2 Kamar Tidur',
          'Dapur',
          'Ruang Tamu',
          'Carport',
          'Taman'
        ],
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Rumah+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Rumah+2',
        ],
        discountType: 'flat',
        discountValue: 2000000,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
