import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🔹 Fetch transactions by buyer (Mahasiswa)
  Future<void> fetchMyTransactions(int buyerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _dbHelper.queryTransactionsWithProduct(
        'buyer_id = ?',
        [buyerId],
      );

      _transactions = maps.map((m) => TransactionModel.fromJoinQuery(m)).toList();
      print('✅ Loaded ${_transactions.length} transactions for buyer $buyerId');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Fetch incoming orders by seller (Penyedia)
  Future<void> fetchIncomingOrders(int sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _dbHelper.queryTransactionsWithProduct(
        'seller_id = ?',
        [sellerId],
      );

      _transactions = maps.map((m) => TransactionModel.fromJoinQuery(m)).toList();
      print('✅ Loaded ${_transactions.length} incoming orders for seller $sellerId');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading incoming orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Create transaction (saat Mahasiswa klik "Beli")
  Future<bool> createTransaction({
    required int productId,
    required int buyerId,
    required int sellerId,
    required int quantity,
    required double totalPrice,
    String? buyerNotes,
  }) async {
    try {
      // 1. Cek stok dulu
      final product = await _dbHelper.queryById('marketplace', productId);
      if (product == null) {
        _error = 'Produk tidak ditemukan';
        notifyListeners();
        return false;
      }

      final currentStock = product['stock_quantity'] as int;
      if (currentStock < quantity) {
        _error = 'Stok tidak cukup. Tersedia: $currentStock';
        notifyListeners();
        return false;
      }

      // 2. Create transaction
      final transaction = TransactionModel(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
        quantity: quantity,
        totalPrice: totalPrice,
        status: 'pending',
        buyerNotes: buyerNotes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _dbHelper.insert('transactions', transaction.toDatabase());
      print('✅ Transaction created with ID: $id');

      // 3. Reload transactions
      await fetchMyTransactions(buyerId);
      
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating transaction: $e');
      notifyListeners();
      return false;
    }
  }

  // 🔹 Update transaction status (Penyedia accept/reject)
  Future<bool> updateTransactionStatus({
    required int transactionId,
    required String status,
    String? sellerNotes,
  }) async {
    try {
      // 1. Get transaction detail
      final transactionMap = await _dbHelper.queryById('transactions', transactionId);
      if (transactionMap == null) {
        _error = 'Transaksi tidak ditemukan';
        notifyListeners();
        return false;
      }

      final transaction = TransactionModel.fromDatabase(transactionMap);

      // 2. Jika status = accepted → kurangi stok
      if (status == 'accepted') {
        final product = await _dbHelper.queryById('marketplace', transaction.productId);
        if (product == null) {
          _error = 'Produk tidak ditemukan';
          notifyListeners();
          return false;
        }

        final currentStock = product['stock_quantity'] as int;
        final newStock = currentStock - transaction.quantity;

        if (newStock < 0) {
          _error = 'Stok tidak cukup';
          notifyListeners();
          return false;
        }

        // Update stock di marketplace table
        await _dbHelper.update(
          'marketplace',
          {'stock_quantity': newStock, 'updated_at': DateTime.now().toIso8601String()},
          transaction.productId,
        );
        print('✅ Stock updated: $currentStock → $newStock');
      }

      // 3. Update transaction status
      final updatedData = {
        'status': status,
        'seller_notes': sellerNotes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _dbHelper.update('transactions', updatedData, transactionId);
      print('✅ Transaction $transactionId updated to $status');

      // 4. Reload transactions
      final currentTransaction = _transactions.firstWhere((t) => t.id == transactionId);
      await fetchIncomingOrders(currentTransaction.sellerId);

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating transaction status: $e');
      notifyListeners();
      return false;
    }
  }

  // 🔹 Get transactions by status (untuk filter)
  List<TransactionModel> getTransactionsByStatus(String status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  // 🔹 Get transaction count by status
  int getCountByStatus(String status) {
    return _transactions.where((t) => t.status == status).length;
  }

  // 🔹 Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}