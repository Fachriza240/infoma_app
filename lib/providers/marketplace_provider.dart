import 'package:flutter/material.dart';
import '../data/models/marketplace_product_model.dart';
import '../data/local/database_helper.dart';

class MarketplaceProvider extends ChangeNotifier {
  List<MarketplaceProductModel> _products = [];
  List<MarketplaceProductModel> _filteredProducts = [];
  MarketplaceProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

  // Database Helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Search & Filter
  String _searchQuery = '';
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<MarketplaceProductModel> get products => _filteredProducts;
  MarketplaceProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _filteredProducts.isNotEmpty;

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
      print('🔵 MarketplaceProvider: Initializing...');

      // Load dari database
      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('marketplace');

      if (maps.isEmpty) {
        // First time - insert mock data
        print('🟡 No data found, inserting mock data...');
        await _insertMockData();

        // Load again after insert
        final newMaps = await _dbHelper.queryAll('marketplace');
        _products = newMaps
            .map((map) => MarketplaceProductModel.fromDatabase(map))
            .toList();
      } else {
        _products = maps
            .map((map) => MarketplaceProductModel.fromDatabase(map))
            .toList();
      }

      _filteredProducts = List.from(_products);
      print('✅ Loaded ${_products.length} products from SQLite');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing: $e');
      _setError('Failed to initialize: $e');
    }
  }

  /// Insert mock data (first time only)
  Future<void> _insertMockData() async {
    final mockProducts = _getMockProducts();

    for (var product in mockProducts) {
      await _dbHelper.insert('marketplace', product.toDatabase());
    }

    print('✅ Mock data inserted');
  }

  /// Fetch all products
  Future<void> fetchProducts() async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('marketplace');
      _products =
          maps.map((map) => MarketplaceProductModel.fromDatabase(map)).toList();
      _filteredProducts = List.from(_products);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch products by seller ID (untuk penyedia)
  Future<void> fetchMyProducts(int sellerId) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final List<Map<String, dynamic>> maps =
          await _dbHelper.queryAll('marketplace');

      // FILTER: hanya product milik seller ini
      final filteredMaps =
          maps.where((map) => map['seller_id'] == sellerId).toList();

      _products = filteredMaps
          .map((map) => MarketplaceProductModel.fromDatabase(map))
          .toList();
      _filteredProducts = List.from(_products);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Fetch by ID
  Future<void> fetchProductById(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 300));

      final map = await _dbHelper.queryById('marketplace', id);
      if (map != null) {
        _selectedProduct = MarketplaceProductModel.fromDatabase(map);
      } else {
        throw Exception('Produk tidak ditemukan');
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

  /// Filter by condition
  void filterByCondition(String? condition) {
    _selectedCondition = condition;
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
    _selectedCondition = null;
    _minPrice = null;
    _maxPrice = null;
    _applyFilters();
  }

  /// Apply filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            product.name.toLowerCase().contains(_searchQuery) ||
                product.location.toLowerCase().contains(_searchQuery) ||
                product.description.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      if (_selectedCondition != null) {
        if (product.condition != _selectedCondition) return false;
      }

      if (_minPrice != null && product.price < _minPrice!) return false;
      if (_maxPrice != null && product.price > _maxPrice!) return false;

      // Only show active products
      if (product.status != 'active') return false;

      return true;
    }).toList();

    notifyListeners();
  }

  /// CREATE
  Future<bool> createProduct(MarketplaceProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final newProduct = MarketplaceProductModel(
        id: DateTime.now().millisecondsSinceEpoch,
        sellerId: product.sellerId,
        categoryId: product.categoryId,
        name: product.name,
        description: product.description,
        condition: product.condition,
        price: product.price,
        stockQuantity: product.stockQuantity,
        location: product.location,
        latitude: product.latitude,
        longitude: product.longitude,
        images: product.images,
        tags: product.tags,
        status: 'active',
        viewsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert ke SQLite
      await _dbHelper.insert('marketplace', newProduct.toDatabase());

      // Reload dari database
      await fetchProducts();

      _setLoading(false);
      print('✅ Product created successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error creating product: $e');
      return false;
    }
  }

  /// UPDATE
  Future<bool> updateProduct(MarketplaceProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      final updatedProduct = MarketplaceProductModel(
        id: product.id,
        sellerId: product.sellerId,
        categoryId: product.categoryId,
        name: product.name,
        description: product.description,
        condition: product.condition,
        price: product.price,
        stockQuantity: product.stockQuantity,
        location: product.location,
        latitude: product.latitude,
        longitude: product.longitude,
        images: product.images,
        tags: product.tags,
        status: product.status,
        viewsCount: product.viewsCount,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update di SQLite dengan 3 parameter
      await _dbHelper.update(
          'marketplace', updatedProduct.toDatabase(), product.id);

      // Reload dari database
      await fetchProducts();

      if (_selectedProduct?.id == product.id) {
        _selectedProduct = updatedProduct;
      }

      _setLoading(false);
      print('✅ Product updated successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error updating product: $e');
      return false;
    }
  }

  /// DELETE
  Future<bool> deleteProduct(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(milliseconds: 500));

      // Delete dari SQLite
      await _dbHelper.delete('marketplace', id);

      // Reload dari database
      await fetchProducts();

      _setLoading(false);
      print('✅ Product deleted successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  /// Mock data
  List<MarketplaceProductModel> _getMockProducts() {
    return [
      MarketplaceProductModel(
        id: 1,
        sellerId: 1,
        categoryId: 1,
        name: 'Laptop ASUS ROG Zephyrus G14',
        description:
            'Laptop gaming mulus, RAM 16GB, SSD 512GB, RTX 3060. Jarang dipakai, mulus seperti baru. Garansi masih 1 tahun.',
        condition: 'like_new',
        price: 15000000,
        stockQuantity: 1,
        location: 'Bandung, Jawa Barat',
        latitude: -6.9147,
        longitude: 107.6098,
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Laptop+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Laptop+2',
        ],
        tags: ['laptop', 'gaming', 'asus', 'rog'],
        status: 'active',
        viewsCount: 125,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      MarketplaceProductModel(
        id: 2,
        sellerId: 1,
        categoryId: 2,
        name: 'Sepeda Gunung Polygon Premier 5',
        description:
            'Sepeda gunung kondisi baik, sudah upgrade groupset Shimano Deore. Cocok untuk trail dan XC.',
        condition: 'good',
        price: 4500000,
        stockQuantity: 1,
        location: 'Jakarta Selatan',
        latitude: -6.2608,
        longitude: 106.7818,
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Sepeda+1',
          'https://via.placeholder.com/400x300/FFD500/0A1E5E?text=Sepeda+2',
        ],
        tags: ['sepeda', 'gunung', 'polygon', 'mtb'],
        status: 'active',
        viewsCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      MarketplaceProductModel(
        id: 3,
        sellerId: 1,
        categoryId: 3,
        name: 'Buku "Clean Code" by Robert Martin',
        description:
            'Buku programming kondisi baru, belum pernah dibaca. Masih ada plastik pembungkus.',
        condition: 'new',
        price: 350000,
        stockQuantity: 2,
        location: 'Surabaya, Jawa Timur',
        images: [
          'https://via.placeholder.com/400x300/0A1E5E/FFFFFF?text=Buku',
        ],
        tags: ['buku', 'programming', 'clean-code'],
        status: 'active',
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
